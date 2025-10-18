// functions/services/inmet/handler.js
const express = require("express");
const cors = require("cors");
const axios = require("axios");

const app = express();
app.use(cors({ origin: true }));

app.get("*", async (req, res) => {
    const url = req.query.url;
    if (!url) return res.status(400).send("Missing URL param");
    try {
        const response = await axios.get(url);
        res.json(response.data);
    } catch (err) {
        res.status(500).send("Erro INMET: " + err.message);
    }
});


module.exports = app;
