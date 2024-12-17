from flask import Flask, render_template, request, redirect, url_for, jsonify
import boto3
from botocore.exceptions import NoCredentialsError

# Initialize the Flask app
app = Flask(__name__)

# AWS DynamoDB Configuration
AWS_ACCESS_KEY = "xxxxxxx"
AWS_SECRET_KEY = "xxxxxx"
DYNAMODB_REGION = "eu-west-1"
TABLE_NAME = "xxxxxx"

# DynamoDB resource
try:
    dynamodb = boto3.resource(
        'dynamodb',
        aws_access_key_id=AWS_ACCESS_KEY,
        aws_secret_access_key=AWS_SECRET_KEY,
        region_name=DYNAMODB_REGION
    )
    table = dynamodb.Table(TABLE_NAME)
except NoCredentialsError:
    print("AWS credentials not provided or invalid")
    exit(1)

# Home route
@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        cluster_name = request.form.get('cluster_name')
        namespace_name = request.form.get('namespace_name')

        # Insert data into DynamoDB
        if cluster_name and namespace_name:
            table.put_item(
                Item={
                    'ClusterName': cluster_name,
                    'NamespaceName': namespace_name
                }
            )
        return redirect(url_for('index'))  # Redirect back to the main page

    # Fetch all records from DynamoDB
    response = table.scan()
    items = response.get('Items', [])
    return render_template('index.html', items=items)



# Route to delete an entry
@app.route('/delete/<string:cluster_name>/<string:namespace_name>', methods=['POST'])
def delete(cluster_name, namespace_name):
    # Delete the item from DynamoDB
    table.delete_item(
        Key={
            'ClusterName': cluster_name,
            'NamespaceName': namespace_name
        }
    )
    return jsonify({"status": "success"})


@app.route('/data', methods=['GET'])
def get_data():
    response = table.scan()
    items = response.get('Items', [])
    # Return only ClusterName and NamespaceName
    simplified_items = [{"ClusterName": item["ClusterName"], "NamespaceName": item["NamespaceName"]} for item in items]
    return jsonify(simplified_items)



# Run the Flask app
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8000)
