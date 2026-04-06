FROM python:3.13

WORKDIR /code

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY main.py .
COPY files/ files/

ENTRYPOINT [ "python", "main.py" ]