# Calvo

## BACKEND:

	- Open project folder in VSCode (or similar IDE)

	- Open a new terminal

	- Enter:

		cd calvo_backend
		pip install -r requirements.txt

	- Create a file named ".env" inside calvo_backend
		Structure:
			OPENAI_API_KEY=your_openai_api_key
			OPIK_API_KEY=your_opik_api_key
			OPIK_WORKSPACE=your_opik_workspace
			OPIK_PROJECT_NAME=your_opik_project_name

		Add your required API keys inside the file

	- Run backend:

		python run.py

	- Backend will run at:
		- http://0.0.0.0:8000



## FRONTEND:

	- Open project folder in VSCode

	- Open a new terminal

	- Enter:

		cd calvo_frontend
		flutter clean
		flutter pub get
		dart run flutter_launcher_icons

	(Important for Windows users – avoid metadata.bin error)
		Create Gradle cache folder once:
			mkdir D:\gradle-cache
			setx GRADLE_USER_HOME "D:\gradle-cache"

			You may choose any drive path (example uses D:\)

		Close and reopen terminal after running setx.

	- Build release APK:

		flutter build apk --release

	- APK file location:

		calvo_frontend\build\app\outputs\flutter-apk\app-release.apk


## NOTE:
	- Make sure Flutter and Android SDK are installed
	- Recommended Python version: 3.11 or 3.12

## USING ON PHONE:
	- Open apk file and install the app on Android phone.
	
	- Open Settings->Application->The three dots at the top right corner->Special Access->Notification Access->Turn it on for 'calvo' app.

	- Reopen the app.

	- Enjoy!
