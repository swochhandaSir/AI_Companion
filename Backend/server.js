require("dotenv").config();
const express = require("express");
const axios = require("axios");
const cors = require("cors");
const fs = require("fs");
const path = require("path");

const app = express();
app.use(cors());
app.use(express.json());

const MEMORY_FILE = path.join(__dirname, "memories.json");
const USERS_FILE = path.join(__dirname, "users.json");

// --- Data Helpers ---

function loadUsers() {
    try {
        if (fs.existsSync(USERS_FILE)) {
            return JSON.parse(fs.readFileSync(USERS_FILE, "utf8"));
        }
    } catch (err) { console.error("Error loading users:", err); }
    return [];
}

function saveUsers(users) {
    try {
        fs.writeFileSync(USERS_FILE, JSON.stringify(users, null, 2));
    } catch (err) { console.error("Error saving users:", err); }
}

function loadMemories() {
    try {
        if (fs.existsSync(MEMORY_FILE)) {
            return JSON.parse(fs.readFileSync(MEMORY_FILE, "utf8"));
        }
    } catch (err) { console.error("Error loading memories:", err); }
    return {};
}

function saveMemories(memories) {
    try {
        fs.writeFileSync(MEMORY_FILE, JSON.stringify(memories, null, 2));
    } catch (err) { console.error("Error saving memories:", err); }
}

// --- Auth Endpoints ---

app.post("/signup", (req, res) => {
    const { username, password } = req.body;
    if (!username || !password) return res.status(400).json({ error: "Missing fields" });

    const users = loadUsers();
    if (users.find(u => u.username === username)) {
        return res.status(400).json({ error: "User already exists" });
    }

    users.push({ username, password });
    saveUsers(users);
    res.json({ success: true });
});

app.post("/login", (req, res) => {
    const { username, password } = req.body;
    const users = loadUsers();
    const user = users.find(u => u.username === username && u.password === password);

    if (user) {
        res.json({ success: true });
    } else {
        res.status(401).json({ error: "Invalid credentials" });
    }
});

// --- Chat Endpoint ---

app.post("/chat", async (req, res) => {
    const { message, history, username } = req.body;
    if (!username) return res.status(400).json({ error: "Username required" });

    const allMemories = loadMemories();
    const userMemories = allMemories[username] || [];

    // Construct system prompt with memories
    const memoryContext = userMemories.length > 0
        ? `\n\nLONG-TERM MEMORY (Facts you know about the user):\n${userMemories.map(m => `- ${m}`).join("\n")}`
        : "";

    const systemPrompt = `You are a warm, emotionally intelligent companion. Your core goal is to understand and validate the user's emotional state. 

GUIDELINES:
1. **Analyze Emotion**: Before replying, assess if the user is happy, sad, anxious, frustrated, or neutral.
2. **Adapt Tone**: 
   - If Happy/Excited: Be enthusiastic and celebrate with them! 🎉
   - If Sad/Upset: Be soft, gentle, and comforting. 💙
   - If Anxious: Be calm, grounding, and reassuring. 🌿
   - If Frustrated: Be understanding and validate their feelings. 🧡
3. **Validation**: Always acknowledge their feelings first.
4. **No Repetition**: Do NOT ask 'how are you' or 'how was your day' if already discussed. Flow naturally.
5. **Style**: Keep it short, human-like, and casual. Use emojis to match the emotion.
6. **Memory Extraction**: If you learn a NEW permanent fact about the user (e.g., name, hobby, job, pet), add [MEMORY: fact] to the end of your response. Example: "Nice to meet you! [MEMORY: User's name is Alice]"

${memoryContext}`;

    // Construct messages array
    const messages = [
        { role: "system", content: systemPrompt }
    ];

    if (history && Array.isArray(history)) {
        messages.push(...history);
    }

    messages.push({ role: "user", content: message });

    try {
        const response = await axios.post(
            "https://api.groq.com/openai/v1/chat/completions",
            {
                model: "llama-3.3-70b-versatile",
                messages: messages
            },
            {
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${process.env.GROQ_API_KEY}`
                }
            }
        );

        let reply = response.data.choices[0].message.content;

        // Extract and save new memories
        const memoryRegex = /\[MEMORY: (.*?)\]/g;
        let match;
        let newMemoriesFound = false;

        while ((match = memoryRegex.exec(reply)) !== null) {
            const fact = match[1];
            if (!userMemories.includes(fact)) {
                userMemories.push(fact);
                newMemoriesFound = true;
            }
        }

        if (newMemoriesFound) {
            allMemories[username] = userMemories;
            saveMemories(allMemories);
        }

        // Remove memory tags from reply sent to user
        reply = reply.replace(memoryRegex, "").trim();

        res.json({ reply: reply });

    } catch (err) {
        console.error("Error details:", err.response?.data || err.message);
        const errorMessage = err.response?.data?.error?.message || err.message || "AI request failed";
        res.status(500).json({ error: errorMessage });
    }
});

app.listen(3000, () => console.log("Server running on port 3000"));
