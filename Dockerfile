FROM python

WORKDIR /app

COPY requirements.txt queries.py ./

RUN apt -y update && apt -y upgrade

RUN python -m pip install --upgrade pip  && python -m pip install -r requirements.txt

CMD ["python", "queries.py"]