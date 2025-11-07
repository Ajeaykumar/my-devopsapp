from flask import Flask

import os

app = Flask(__name__)

@app.route('/')
def hello():
  return "Hello DevOps World here is your Boss! This is version 2.0!"

if __name__ == '__main__':
   app.run(debug=True, host='0.0.0.0', port=os.environ.get('PORT', 5000))
