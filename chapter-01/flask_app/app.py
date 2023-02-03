from flask import Flask, request
import os.path

app = Flask(__name__)

@app.route("/")
def hello_world():

    name = request.args.get('name')
    if name:
        with open("name.txt", "w") as text_file:
            text_file.write(name)

    name_file = None

    if os.path.exists("name.txt"):
        with open("name.txt") as text_file:
            name_file = text_file.read()

    if name_file:
        return {
            "msg" : f"Hello, {name_file}!"
        }

    return {
        "msg": "Hello, World!"
    }