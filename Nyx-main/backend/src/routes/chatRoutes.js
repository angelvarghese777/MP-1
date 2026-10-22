const express = require("express");

const router = express.Router();

const chatController = require("../controllers/chatController");

router.post("/chat", chatController.postChat);
router.get("/messages/:senderId/:receiverId", chatController.getChat);
router.patch("/messages/delivered", chatController.markDelivered);
router.patch("/messages/read", chatController.markRead);
module.exports = router;