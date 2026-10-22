const pool = require("../config/db");

exports.postChat = async (req, res) => {
  try {
    const {
      sender_id,
      receiver_id,
      message,
      client_message_id,
    } = req.body;

    await pool.query(
      `INSERT INTO messages
        (sender_id, receiver_id, message, client_message_id)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (client_message_id) DO NOTHING`,
      [
        sender_id,
        receiver_id,
        message,
        client_message_id ?? null,
      ]
    );

    res.json({
      success: true,
      message: "Message saved",
    });
  } catch (error) {
    console.error("Error saving message:", error);
    res.status(500).json({
      success: false,
      message: "Failed to save message",
    });
  }
};

exports.getChat = async (req, res) => {
    try {
        const { senderId, receiverId } = req.params;
         const messagesQuery = await pool.query(
            `SELECT *
             FROM messages
             WHERE
             (sender_id = $1 AND receiver_id = $2)
             OR
             (sender_id = $2 AND receiver_id = $1)
             ORDER BY created_at ASC`,
            [senderId, receiverId]
        );
        res.json({
           success: true,
            messages: messagesQuery.rows
        });
       
    } catch (error) {
        console.error("Error occurred while fetching messages:", error);
        res.status(500).json({
            success: false,
            message: "An error occurred while fetching messages."
        });
    }
};



exports.markDelivered = async (req, res) => {
  try {
    const { messageId, receiverId } = req.body;

    const result = await pool.query(
      `UPDATE messages
       SET delivered_at = COALESCE(delivered_at, NOW())
       WHERE id = $1
         AND receiver_id = $2
       RETURNING id, delivered_at, read_at`,
      [messageId, receiverId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Message not found for this recipient",
      });
    }

    res.json({
      success: true,
      message: result.rows[0],
    });
  } catch (error) {
    console.error("Delivery receipt error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to mark message delivered",
    });
  }
};

exports.markRead = async (req, res) => {
  try {
    const { messageId, receiverId } = req.body;

    const result = await pool.query(
      `UPDATE messages
       SET delivered_at = COALESCE(delivered_at, NOW()),
           read_at = COALESCE(read_at, NOW())
       WHERE id = $1
         AND receiver_id = $2
       RETURNING id, delivered_at, read_at`,
      [messageId, receiverId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Message not found for this recipient",
      });
    }

    res.json({
      success: true,
      message: result.rows[0],
    });
  } catch (error) {
    console.error("Read receipt error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to mark message read",
    });
  }
};
