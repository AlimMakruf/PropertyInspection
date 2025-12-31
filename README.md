
# PropertyInspection
### Create simple app regarding property inspection
# Setup Instructions
### Prerequisites
- Install Salesforce CLI
- Install Visual Studio Code
- Install the Visual Studio Code Salesforce extensions, including the Lightning Web Components extension

### Instalation Steps
1. Clone the repository
   ```git clone https://github.com/AlimMakruf/PropertyInspection.git```

2. Authenticate to Salesforce
   ```sfdx auth:web:login -a DevOrg```
   Replaces DevOrg with a descriptive name for your org (e.g., DevHub, UATSandbox).

4. Deploy metadata
   ```sfdx force:source:deploy -p force-app```

# Approach to Requirement
- Read all the requirement and identify which one is related ( and so far, information in PDF was good ) and all i do is only follow step by step in pdf.
- The solution that i use, i try my best to followed salesforce best practices.

# Limitation
- From all of the task, the only thing that i can't make "refresh after adding". My target is to refresh only the table, but i don't know why this not work.

# Screenshot for all the work
### Custom Object Creation
<img width="1679" height="865" alt="image" src="https://github.com/user-attachments/assets/859d3059-1e7b-48e3-980c-c5e8b068c05e" />
<img width="2560" height="1008" alt="image" src="https://github.com/user-attachments/assets/b175cb9b-840a-41d8-be63-d35bb785fb63" />

### Coverage Test Class
<img width="1680" height="206" alt="image" src="https://github.com/user-attachments/assets/ea123426-39a9-4c3d-bf88-76fdf57668c7" />

### Flow Screen UI
<img width="672" height="566" alt="image" src="https://github.com/user-attachments/assets/3920cad2-987a-40c6-9f18-47c4df723215" />

### Flow Builder Diagram
<img width="1235" height="1197" alt="image" src="https://github.com/user-attachments/assets/d9fabe9e-eb08-4977-98cc-9383fee47459" />

### LWC UI
<img width="1724" height="1042" alt="image" src="https://github.com/user-attachments/assets/9c563a63-2786-42e9-a687-0e52a0f85093" />






