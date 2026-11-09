"""AI symptom triage service using the official Google GenAI client."""

import os

from google import genai


def analyze_pig_symptoms(symptoms_description):
    """Analyze swine symptoms via Gemini and return a structured triage."""
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return {"error": True, "message": "Walang natagpuang GEMINI_API_KEY sa environment variables."}

    try:
        client = genai.Client(api_key=api_key)

        prompt = f"""
        Ikaw ay isang eksperto at beterinaryo sa pag-aalaga ng baboy (swine veterinarian).
        Suriin ang mga sumusunod na sintomas ng baboy at magbigay ng structured health triage:

        Mga Sintomas: {symptoms_description}

        Ibigay ang iyong payo sa sumusunod na format:
        1. **Posibleng Sakit / Ailment:** (Ano ang posibleng dinaramdam)
        2. **Urgency Level:** (Mababa, Katamtaman, o Kritikal/Kailangang I-isolate agad)
        3. **Mga Inirerekomendang Gamot o Lunas:** (Mga karaniwang gamot o bitamina)
        4. **Biosecurity / Prevention Steps:** (Paano maiwasan na mahawa ang iba)
        """

        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
        )

        return {
            "error": False,
            "response_text": response.text
        }

    except Exception as e:
        return {
            "error": True,
            "message": str(e)
        }
