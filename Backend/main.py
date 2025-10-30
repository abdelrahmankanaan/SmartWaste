import os
import jwt
import pandas as pd
from datetime import datetime, timedelta
from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from passlib.context import CryptContext
from sklearn.neighbors import NearestNeighbors
from typing import List, Optional
from supabase import create_client, Client
from dotenv import load_dotenv
# python -m uvicorn main:app --reload
load_dotenv()

# Supabase Setup
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Security
SECRET_KEY = os.getenv("SECRET_KEY", "supersecretkey")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Pydantic models
class UserCreate(BaseModel):
    username: str
    email: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class IngredientsRequest(BaseModel):
    ingredients: List[str]

# Helper Functions
def get_password_hash(password):
    return pwd_context.hash(password)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_user_by_username(username: str):
    result = supabase.table("users").select("*").eq("username", username).single().execute()
    return result.data if result.data else None

def authenticate_user(username: str, password: str):
    user = get_user_by_username(username)
    if not user or not verify_password(password, user["hashed_password"]):
        return False
    return user

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta if expires_delta else timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# Load Data & Train KNN
df_raw = pd.read_csv("data/data_lebanese-dishes.csv")
df_onehot = df_raw.drop(columns=["Source", "Dish", "Ingredients"], errors="ignore")
knn = NearestNeighbors(n_neighbors=5, metric='cosine')
knn.fit(df_onehot)

# FastAPI App
app = FastAPI()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Endpoints
@app.post("/register", status_code=status.HTTP_201_CREATED)
async def register(user: UserCreate):
    existing = supabase.table("users").select("*").or_(
        f"username.eq.{user.username},email.eq.{user.email}"
    ).execute()
    if existing.data:
        raise HTTPException(status_code=400, detail="Username or email already registered")

    hashed_password = get_password_hash(user.password)
    supabase.table("users").insert({
        "username": user.username,
        "email": user.email,
        "hashed_password": hashed_password
    }).execute()
    return {"message": "User created successfully"}

@app.post("/token", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    token = create_access_token(data={"sub": user["username"]}, expires_delta=access_token_expires)
    return {"access_token": token, "token_type": "bearer"}

@app.get("/ingredients")
def get_ingredients():
    return {"ingredients": df_onehot.columns.tolist()}

@app.post("/recommend")
def recommend_dishes(request: IngredientsRequest):
    if not request.ingredients:
        raise HTTPException(status_code=400, detail="No ingredients provided.")

    user_vector = pd.DataFrame(
        [[1 if col in request.ingredients else 0 for col in df_onehot.columns]],
        columns=df_onehot.columns
    )
    distances, indices = knn.kneighbors(user_vector)
    results = []
    for idx, dist in zip(indices[0], distances[0]):
        similarity = (1 - dist) * 100
        dish_name = df_raw.iloc[idx]["Dish"]
        ingredients = df_raw.iloc[idx]["Ingredients"]
        results.append({
            "dish": dish_name,
            "similarity": round(similarity, 2),
            "ingredients": ingredients
        })

    return {"recommendations": results}
