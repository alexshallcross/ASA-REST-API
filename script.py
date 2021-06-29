import requests
import json

url = "https://192.168.0.2/api/objects/networkobjects"

payload = json.dumps({
  "kind": "object#NetworkObj",
  "name": "TestNetworkRangeObj",
  "host": {
    "kind": "IPv4Network",
    "value": "12.12.12.0/24"
  }
})
headers = {
  'Authorization': 'Basic Y2lzY286Y2lzY28=',
  'Content-Type': 'application/json',
  'User-Agent': 'REST API Agent'
}

response = requests.request("GET", url, headers=headers, data=payload, verify=False)

print(response.text)
