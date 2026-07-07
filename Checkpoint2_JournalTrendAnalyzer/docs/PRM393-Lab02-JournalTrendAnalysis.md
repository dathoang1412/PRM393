# PRM393 – Mobile Programming
## Lab 2: Journal Trend Analysis Mobile Application

---

## 1. Introduction

Research publications are growing rapidly across many disciplines, making it increasingly important to identify emerging topics, influential papers, active researchers, and publication trends. Academic databases such as OpenAlex provide access to large-scale scholarly data that can be used for research analytics and decision support.

In this assignment, students will develop a Flutter-based mobile application that retrieves publication data from OpenAlex and provides analytical insights through interactive visualizations and dashboards. The application should help users explore research trends for a selected topic and gain a better understanding of the corresponding research landscape.

## 2. Learning Objectives

Upon successful completion of this assignment, students will be able to:

- Develop cross-platform mobile applications using Flutter.
- Integrate and consume RESTful APIs.
- Process and analyze JSON data from external sources.
- Implement asynchronous programming and state management.
- Design user-friendly mobile interfaces.
- Visualize analytical data using charts and dashboards.
- Apply AI-assisted code review techniques to improve software quality.
- Organize software projects using maintainable architecture and coding practices.

## 3. Assignment Requirements

Students are required to develop a mobile application named **Journal Trend Analyzer** that uses the **OpenAlex API** as the primary data source.

The application must allow users to search for a research topic and analyze the retrieved publication data. Topics may include Artificial Intelligence, Software Engineering, Data Science, Cybersecurity, Internet of Things, Blockchain, or any topic entered by the user.

All data displayed in the application must be retrieved dynamically from OpenAlex. **The use of hard-coded datasets is not allowed.**

### 3.1 Out of Scope

To ensure that students focus on mobile application development, API integration, data visualization, and trend analysis, the following features are explicitly excluded from the scope of this assignment:

- Developing custom backend services or REST APIs.
- Implementing user authentication or authorization mechanisms.
- User registration, login, password management, or role-based access control.
- Database design and deployment.
- Data persistence on cloud platforms.
- Real-time data synchronization.
- Push notifications.
- Payment processing features.
- Social networking features such as comments, likes, or sharing.
- Administrative dashboards.
- Machine learning model training or deployment.
- Web application development.

Students must use the OpenAlex API as the sole external data source for retrieving publication information and performing trend analysis. The application should consume OpenAlex data directly from the mobile client without introducing additional backend components.

## 4. Functional Requirements

### 4.1 Topic Search

The application shall allow users to search for research publications by entering a topic keyword. Search results should display essential publication information, including the publication title, publication year, citation count, and journal name.

### 4.2 Publication Details

The application shall provide a detailed view for each publication. The detail screen should include information such as publication title, authors, publication year, journal name, citation count, DOI, and abstract when available.

### 4.3 Publication Trend Analysis

The application shall analyze publication activity over time by grouping publications according to publication year. The result should be visualized using an appropriate chart to illustrate the growth or decline of the selected research topic.

### 4.4 Top Influential Papers

The application shall identify and display the most influential publications based on citation counts. Publications should be ranked from highest to lowest citation count.

### 4.5 Top Research Journals

The application shall identify journals that contribute the largest number of publications related to the selected research topic. The result should be presented using a ranked list or chart.

### 4.6 Top Contributing Authors

The application shall identify authors who have published the highest number of papers related to the selected research topic. The result should clearly present author names and publication counts.

### 4.7 Research Trend Dashboard

The application shall provide a dashboard summarizing key insights for the selected topic. The dashboard should include:

- Total publications
- Average citation count
- Most active publication year
- Top journal
- Top author
- Most influential paper

## 5. Technical Requirements

The application must be developed using **Flutter** and **Dart**.

Students must implement API integration, asynchronous data retrieval, JSON processing, error handling, loading states, and data visualization. The project should follow a clean and maintainable structure with appropriate separation of concerns between user interface, business logic, and data access layers.

At minimum, the project should contain dedicated modules or folders for:

- `models`
- `services`
- `screens`
- `widgets`
- state management components

The application must run successfully on Android devices and Android emulators.

## 6. AI-Assisted Code Review

As part of the software quality assurance process, students are required to conduct an AI-assisted code review before submission.

Students may use tools such as **SonarQube**, **Kodus AI**, **CodeRabbit**, or **GitHub Copilot Code Review**.

The code review must identify **at least three issues**, warnings, code smells, bugs, security concerns, or improvement opportunities. Students should address the findings whenever appropriate and document the review process in the project report.

Evidence of the review process must be provided through screenshots and brief explanations of the detected issues and implemented improvements.

## 7. User Interface Requirements

The application must contain at least **four major screens**:

- Search Screen
- Publication Detail Screen
- Trend Analysis Screen
- Research Dashboard Screen

Students may introduce additional screens or features to enhance usability and user experience.

The user interface should be responsive, visually consistent, and easy to navigate.

## 8. Deliverables

### 8.1 Source Code

Students shall submit the complete source code through a GitHub repository named according to the following convention:

```
PRM393_Lab2_StudentID
```

The repository must contain all source files and any additional resources required to run the application.

### 8.2 Project Report

Students shall submit a project report of approximately **5–10 pages** in PDF format.

The report should include:

- Project overview
- System design
- Implementation details
- API integration approach
- Screenshots of major features
- Trend analysis results
- AI-assisted code review findings
- Challenges encountered and lessons learned

### 8.3 Demonstration Video

Students shall submit a demonstration video with a duration of approximately **5–10 minutes**.

The video should demonstrate the implemented features, including topic search, publication details, publication trend analysis, top journals, top authors, dashboard analytics, and the AI-assisted code review process.
