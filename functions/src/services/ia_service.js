// functions/src/services/ia_service.js
const OpenAI = require('openai');

let openaiClient = null;

/// Retorna o cliente da OpenAI, inicializando apenas quando for preciso
function getOpenAiClient() {
    const apiKey = process.env.OPENAI_API_KEY;

    if (!apiKey) {
        // Só dá erro quando realmente tentamos usar a IA
        console.error('OPENAI_API_KEY não definida. Verifique o arquivo .env em functions/.');
        throw new Error('OPENAI_API_KEY não definida no ambiente.');
    }

    if (!openaiClient) {
        openaiClient = new OpenAI({ apiKey });
    }

    return openaiClient;
}

/**
 * Recebe a mensagem do usuário e retorna a resposta da IA
 */
async function askIa(message) {
    const openai = getOpenAiClient();

    const completion = await openai.chat.completions.create({
        // ✅ modelo correto e barato
        model: 'gpt-4o-mini',
        messages: [
            {
                role: 'system',
                content: `
          Você é o assistente de IA do SIPGED,
          especializado em processos administrativos,
          contratação pública, DFD, edital, contratos, aditivos,
          validades, medições e cronogramas de obras rodoviárias.
          Responda de forma objetiva, clara e prática.
        `,
            },
            {
                role: 'user',
                content: message,
            },
        ],
        max_tokens: 300,
        temperature: 0.3,
    });

    const reply =
    completion.choices?.[0]?.message?.content ||
    'Não consegui gerar uma resposta no momento.';

    return reply;
}

module.exports = { askIa };
