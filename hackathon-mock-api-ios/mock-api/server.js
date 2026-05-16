const express = require("express");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = 3001;

app.use(express.json());

// Serve image files from the local "images" directory
// Handles URLs like /images//img17m.jpg (double-slash from paths starting with "/")
app.use("/images", express.static(path.join(__dirname, "images")));

function readJson(fileName) {
  const filePath = path.join(__dirname, "responses", fileName);
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function delayedJson(res, fileName, status = 200, delay = 500) {
  setTimeout(() => {
    res.status(status).json(readJson(fileName));
  }, delay);
}

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.post("/login", (req, res) => {
  const { email, password } = req.body || {};
  if (email === "demo@hackathon.com" && password === "123456") {
    return delayedJson(res, "login_success.json", 200, 400);
  }
  return delayedJson(res, "error_401.json", 401, 400);
});

app.get("/profile", (req, res) => {
  return delayedJson(res, "profile.json", 200, 600);
});

app.get("/feed", (req, res) => {
  return delayedJson(res, "feed.json", 200, 700);
});

app.get("/skus", (req, res) => {
  return delayedJson(res, "skus.json", 200, 700);
});


app.listen(PORT, "0.0.0.0", () => {
  console.log(`Mock API running on http://0.0.0.0:${PORT}`);
});