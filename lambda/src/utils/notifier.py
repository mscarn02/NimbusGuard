import json
import urllib3

def send_discord_notification(webhook_url, message):
	http = urllib3.PoolManager()

	data = {
		"content": "Nimbus cloud security alert",
		"embeds": [{
            "title": "Remediation Triggered",
            "description": message,
            "color": 15158332 # Red color code
        }]
	}
	#print('Raw data received:',data)

	encoded_data = json.dumps(data).encode('utf-8')	#convert data into JSON and .encode converts text into bytes
	#print('encoded data:',encoded_data)
	response = http.request(
			'POST',
			webhook_url,
			body=encoded_data,
			headers={'Content-Type': 'application/json'}
		)
	return response.status

if __name__ == "__main__":
	
	TEST_URL = os.environ.get('DISCORD_WEBHOOK_URL')
	test_msg = "Communication check: Connection established."
	print(f"Status: {send_discord_notification(TEST_URL, test_msg)}")