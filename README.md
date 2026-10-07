<div align="center">

<!-- ============ APP LOGO SLOT ============
     Replace docs/assets/logo.svg with your own logo (or change this path to docs/assets/logo.png).
     Keep it square, 512 x 512 px or larger. -->
<img src="https://github.com/Nirmana-KAS/Tempate-Photo/blob/main/logo.png" alt="GemEye logo" width="250"/>

<img src="docs/assets/banner.svg" alt="GemEye" width="100%"/>

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![TensorFlow](https://img.shields.io/badge/TensorFlow-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![AWS S3](https://img.shields.io/badge/AWS_S3-569A31?style=for-the-badge&logo=amazons3&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)

**Photo in, certified grade out.** 1 to 5 mm blue sapphires graded on a 7-grade GEMCLOUD scale.

</div>

---

## Architecture

<img src="docs/assets/architecture.svg" alt="Architecture" width="100%"/>

## Grading pipeline

<img src="docs/assets/pipeline.svg" alt="Grading pipeline" width="100%"/>

## Quality gates

<img src="docs/assets/gates.svg" alt="Quality gates" width="100%"/>

## Model

<img src="docs/assets/model.svg" alt="Ensemble model" width="100%"/>

## Two colour paths

<img src="docs/assets/colour-paths.svg" alt="Model path and display path" width="100%"/>

## Explainability

<img src="docs/assets/gradcam.svg" alt="Grad-CAM" width="100%"/>

## Certificates

<img src="docs/assets/certificate.svg" alt="Certificates" width="100%"/>

## Security

<img src="docs/assets/security.svg" alt="Security layers" width="100%"/>

## Results

<img src="docs/assets/results.svg" alt="Verification results" width="100%"/>

## API

19 endpoints: 3 public (`/health`, `/config`, `/public/v/{slug}`) and 16 authenticated. Interactive docs at `/docs`.

## Run locally

```bash
cd backend
docker compose up -d --build        # API on http://<LAN-IP>:8000
curl http://localhost:8000/health

cd ../app
flutter build apk --release --dart-define=API_BASE_URL=http://<LAN-IP>:8000
```

Needs `backend/.env` and `backend/models/` (not in git). Phone and laptop on the same Wi-Fi.

## Roadmap

<img src="docs/assets/roadmap.svg" alt="Roadmap" width="100%"/>

<div align="center">

<sub>K.A.S. Nirmana · BSc (Hons) Computer Science · NSBM Green University · Research project</sub>

</div>
