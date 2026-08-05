const express = require('express');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');

const router = express.Router();

// Initialize Gemini AI client
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

// ─── POST /api/ai/explain ──────────────────────────────────────────────────────
// Explains a concept from provided text context, answering a student's question.
// Body: { text?: string, question: string }
router.post('/explain', verifyFirebaseToken, async (req, res) => {
  const { text, question } = req.body;

  if (!question || question.trim().length === 0) {
    return res.status(400).json({ error: 'A question is required.' });
  }

  try {
    let prompt;

    if (text && text.trim().length > 0) {
      // PDF-context mode: answer using document text
      prompt = `You are a helpful academic study assistant called "UniNotes AI".
      
A student is reading the following academic document:
---
${text.slice(0, 8000)} ${text.length > 8000 ? '\n[... document truncated for length ...]' : ''}
---

The student asks: "${question}"

Please provide a clear, accurate, and student-friendly explanation. Use simple language, examples where helpful, and structure your answer with bullet points or numbered lists if appropriate. If the answer isn't in the document, use your general knowledge and mention it.`;
    } else {
      // Free-form mode: general academic question
      prompt = `You are a helpful academic study assistant called "UniNotes AI".

A university student asks: "${question}"

Please provide a clear, accurate, and student-friendly explanation. Use simple language, real-world examples where appropriate, and structure your answer with bullet points or numbered lists if it helps clarity.`;
    }

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const answerText = response.text();

    res.json({
      success: true,
      answer: answerText,
      mode: text ? 'document-context' : 'free-form',
    });
  } catch (error) {
    console.error('AI explain error:', error.message);
    res.status(500).json({ error: 'Failed to generate explanation. Please try again.' });
  }
});

// ─── POST /api/ai/summarize ────────────────────────────────────────────────────
// Summarizes a provided document text.
// Body: { text: string, title?: string }
router.post('/summarize', verifyFirebaseToken, async (req, res) => {
  const { text, title } = req.body;

  if (!text || text.trim().length === 0) {
    return res.status(400).json({ error: 'Document text is required for summarization.' });
  }

  try {
    const prompt = `You are a helpful academic study assistant called "UniNotes AI".

Please summarize the following academic document${title ? ` titled "${title}"` : ''}:
---
${text.slice(0, 10000)} ${text.length > 10000 ? '\n[... document truncated for length ...]' : ''}
---

Provide a structured summary with:
1. **Overview** – A 2-3 sentence high-level description of the document.
2. **Key Concepts** – The most important topics, theories, or definitions covered.
3. **Key Takeaways** – The main conclusions or points a student should remember.

Keep the summary concise and student-friendly.`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const summaryText = response.text();

    res.json({
      success: true,
      summary: summaryText,
    });
  } catch (error) {
    console.error('AI summarize error:', error.message);
    res.status(500).json({ error: 'Failed to generate summary. Please try again.' });
  }
});

module.exports = router;
