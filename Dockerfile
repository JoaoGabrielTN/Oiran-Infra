FROM python

WORKDIR /app

COPY queries.ipynb .

RUN apt -y update && apt -y upgrade

RUN pip install jupyter pandas 
