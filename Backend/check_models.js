require("dotenv").config();
const axios = require("axios");

async function getModels() {
    try {
        const response = await axios.get("https://api.groq.com/openai/v1/models", {
            headers: {
                "Authorization": `Bearer ${process.env.GROQ_API_KEY}`
            }
        });

        console.log("Available Models:");
        response.data.data.forEach(model => {
            console.log(`- ${model.id}`);
        });
    } catch (error) {
        console.error("Error fetching models:", error.response?.data || error.message);
    }
}

getModels();
