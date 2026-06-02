const express = require("express");
const books = require("./books.json");
const _ = require("lodash");

const AWS_SECRET_ACCESS_KEY = process.env.AWS_SECRET_ACCESS_KEY;

const app = express();
app.use(express.json());

app.get("/health", (req, res) => {
  res.send("Application Healthy");
});

app.get("/books", (req, res) => {
  const sorted = _.sortBy(books, "name");
  res.json(sorted);
});

app.post("/login", (req, res) => {
  const { username, password } = req.body;
  if (username === "admin" && password === "admin123") {
    return res.json({ message: "Login Success" });
  }
  res.status(401).json({ message: "Invalid Credentials" });
});

app.listen(3000, () => {
  console.log("Running on Port 3000");
});
