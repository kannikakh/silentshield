import pandas as pd
import joblib
import re

from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report

with open("English_Scam.txt", "r", encoding="utf-8") as f:
    scam_lines = f.readlines()

with open("English_NonScam.txt", "r", encoding="utf-8") as f:
    safe_lines = f.readlines()

def clean_lines(lines):

    cleaned = []

    for line in lines:

        line = line.strip()

        # remove empty lines
        if line == "":
            continue

        # remove numbering like "1."
        line = re.sub(r"^\d+\.\s*", "", line)

        cleaned.append(line)

    return cleaned


scam_texts = clean_lines(scam_lines)
safe_texts = clean_lines(safe_lines)

texts = scam_texts + safe_texts

labels = [1] * len(scam_texts) + [0] * len(safe_texts)

df = pd.DataFrame({
    "text": texts,
    "label": labels
})


print(df.head())
print("\nTotal Samples:", len(df))

X_train, X_test, y_train, y_test = train_test_split(
    df["text"],
    df["label"],
    test_size=0.2,
    random_state=42
)

model = Pipeline([

    ("tfidf", TfidfVectorizer(
        stop_words="english",
        lowercase=True
    )),

    ("classifier", LogisticRegression())

])

model.fit(X_train, y_train)

predictions = model.predict(X_test)

accuracy = accuracy_score(y_test, predictions)

print("\nAccuracy:", accuracy)

print("\nClassification Report:\n")
print(classification_report(y_test, predictions))

joblib.dump(model, "scam_detector_model.pkl")

print("\nModel Saved Successfully!")
