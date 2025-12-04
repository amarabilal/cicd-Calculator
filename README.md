# README – Projet CI/CD & Sécurité Web

---

# Projet CI/CD sécurisé – Application Python *Calculator*

**Auteur :** Bilal Amara

**Année :** 2025 – 2026

**Projet :** CI/CD + Sécurité Web Offensive

**Enseignant :** Kevin Detroy

---

# **1. Description du projet**

Ce projet met en œuvre un pipeline **CI/CD complet et sécurisé** autour d’une application Python simple (*Calculator*), tout en intégrant des principes **DevSecOps** avancés.

L’objectif est double :

1. **Construire un pipeline CI/CD complet**
    - Tests multi-version Python
    - Linting flake8
    - Tests unitaires Pytest
    - Analyse de vulnérabilités avec Trivy
    - Build & Push de l'image Docker vers Docker Hub
2. **Réaliser 11 challenges de sécurité Web offensive**
    - File Path Traversal
    - PHP Filters
    - CSRF (différents contournements)
    - JWT révoqué
    - SQL Injection Error
    - XSS stockée
    - Command Injection
    - SSTI
    - API Mass Assignment

Toutes les résolutions se trouvent dans :

**`CHALLENGES_RAPPORT.md`**

---

# **2. Architecture CI/CD**

### **CI : Continuous Integration**

Déclenchée sur :

- `push` → `main` / `master`
- `workflow_dispatch`

Fonctionnalités :

- Matrix Python : 3.8, 3.9, 3.10
- Qualité de code : flake8
- Tests unitaires : pytest
- Analyse de vulnérabilités (SCA) avec Trivy
- Upload des rapports SARIF vers GitHub Security

### **CD : Continuous Delivery**

Déclenchée uniquement si :

> Le workflow "CI" a réussi (workflow_run + conclusion==success)
> 

Fonctionnalités :

- Login Docker Hub (secrets GitHub)
- Build image multi-stage
- Push automatique :
    
    `docker.io/<username>/calculator:latest`
    

---

# **3. Pipeline CI complet (`.github/workflows/ci.yml`)**

```yaml
name: CI

on:
  push:
    branches:
      - main
      - master
  workflow_dispatch:

permissions:
  contents: read
  security-events: write
  actions: read

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.8", "3.9", "3.10"]

    steps:
      - name: checkout
        uses: actions/checkout@v5

      - name: Python ${{ matrix.python-version }}
        uses: actions/setup-python@v6
        with:
          python-version: ${{ matrix.python-version }}

      - name: dependencies
        run: |
          python -m pip install --upgrade pip
          pip install flake8 pytest

      - name: flake8
        run: |
          flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
          flake8 . --count --exit-zero --statistics

      - name: pytest
        run: |
          pytest tests/

  trivy-scan:
    runs-on: ubuntu-latest

    steps:
      - name: checkout
        uses: actions/checkout@v5

      - name: trivy FS mode
        uses: aquasecurity/trivy-action@0.33.1
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: upload
        uses: github/codeql-action/upload-sarif@v4
        with:
          sarif_file: 'results.sarif'

```

---

# **4. Pipeline CD complet (`.github/workflows/cd.yml`)**

```yaml
name: CD

on:
  workflow_run:
    workflows: ["CI"]
    types:
      - completed

jobs:
  build:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}

    steps:
      - name: checkout
        uses: actions/checkout@v5

      - name: login
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: build and push
        id: push
        uses: docker/build-push-action@v6
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/calculator:latest

```

---

# **5. Dockerfile sécurisé (multi-stage + non-root)**

```docker
FROM python:3.10-alpine AS builder

WORKDIR /app

RUN apk add --no-cache gcc python3-dev musl-dev linux-headers

COPY requirements.txt .

RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

FROM python:3.10-alpine

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup && \
    mkdir -p /app && \
    chown -R appuser:appgroup /app

WORKDIR /app

COPY --from=builder --chown=appuser:appgroup /opt/venv /opt/venv
COPY --chown=appuser:appgroup calculator/ ./calculator/

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "from calculator.calculator import add; assert add(1,1) == 2" || exit 1

CMD ["python", "calculator/calculator.py"]

```

---

# **6. Structure du projet**

```
├── calculator/
│   ├── calculator.py
│   ├── __init__.py
│
├── tests/
│   ├── test_calculator.py
│
├── requirements.txt
├── Dockerfile
├── CHALLENGES_RAPPORT.md  ← challenges web (11)
├── README.md  ← vous êtes ici
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── cd.yml

```

---

# **7. Sécurité & DevSecOps**

### Docker sécurisé

- Multi-stage → surface d'attaque réduite
- Non-root (`USER appuser`)
- Alpine Linux → image minimale
- Healthcheck applicatif

### CI : sécurité intégrée (shift-left)

- Trivy (CRITICAL/HIGH) → SCA
- Rapports SARIF GitHub Security
- Lint strict flake8 (E9/F7/F63/F82)

---

# **8. Partie Sécurité Web (Challenges)**

Le fichier complet se trouve ici :

**`CHALLENGES_RAPPORT.md`**

Il contient pour **11 challenges** :

- Analyse
- Étapes
- Payload
- Capture d'écran
- Recommandations (avec sources OWASP/PortSwigger)

---

# **9. Installation & Exécution locale**

### Installation

```bash
pip install -r requirements.txt

```

### Lancer l'application Python

```bash
python calculator/calculator.py

```

### Construire l’image Docker

```bash
docker build -t calculator .

```

### Exécuter le conteneur

```bash
docker run calculator

```

---

# **10. Liens utiles**

- GitHub Actions : [https://docs.github.com/actions](https://docs.github.com/actions)
- Pytest : [https://docs.pytest.org](https://docs.pytest.org/)
- Trivy : [https://github.com/aquasecurity/trivy-action](https://github.com/aquasecurity/trivy-action)
- Docker Build-Push : [https://github.com/docker/build-push-action](https://github.com/docker/build-push-action)
- OWASP : [https://owasp.org](https://owasp.org/)
- PortSwigger Web Academy : [https://portswigger.net/web-security](https://portswigger.net/web-security)

---