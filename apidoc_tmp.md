## 1. Endpoint

GET: http://localhost:3000/api/v0/user/preferences

### Functionality

Fetches user preferences.

### Requestheader

```
access_token: ...
```

### Responsebody

```
{
    "preferences": {
        "id": null,
        "user_id": 29,
        "interests": null,
        "experience": null,
        "degree": null,
        "num_jobs_done": 0,
        "gender": null,
        "spontaneity": null,
        "job_types": {
            "1": 0,
            "2": 0,
            "3": 0
        },
        "key_skills": null,
        "salary_range": [
            0.0,
            0.0
        ],
        "cv_url": null
    }
}
```

---

## 2. Endpoint

GET: http://localhost:3000/api/v0/user/jobs

### Functionality

Fetches own jobs (= jobs created by user).

### Requestheader

```
access_token: ...
```

### Responsebody

```
{
    "jobs": [
        {
            ...
        },
        {
            ...
        }
    ]
}
```

---

## 3. Endpoint

GET: http://localhost:3000/api/v0/user/applications

### Functionality

Fetches own applications (= applications submitted by user).

### Requestheader

```
access_token: ...
```

### Responsebody

```
...TODO
```

---

## 4. Endpoint

GET: http://localhost:3000/api/v0/user/upcoming

### Functionality

Fetches upcoming jobs (= jobs that the user applied for and got accepted).

### Requestheader

```
access_token: ...
```

### Responsebody

```
{
    "jobs": [
        {
            ...
        },
        {
            ...
        }
    ]
}
```

---

## 5. Endpoint

POST: http://localhost:3000/api/v0/user/image

### Functionality

Uploads a new profile image for a user.

### Requestheader

```
access_token: ...
```

### Requestbody (form-data)

```
image_url=<new profile image>
```

---

## 6. Endpoint

GET: http://localhost:3000/api/v0/jobs/66

### Functionality

Fetches single job.

### Requestheader

```
access_token: ...
```

### Responsebody

```
{
    "job": {
        "job_id": 66,
        "job_type": "Manufacturing",
        "job_type_value": 16,
        "job_status": 0,
        "status": "public",
        "user_id": 29,
        "duration": 342,
        "code_lang": null,
        "title": "Test new phones",
        "position": "Materials expert",
        "description": {
            "id": 66,
            "name": "description",
            "body": "<div>This is a great job!</div>",
            "record_type": "Job",
            "record_id": 66,
            "created_at": "2023-09-12T19:45:12.531Z",
            "updated_at": "2023-09-12T19:45:12.531Z"
        },
        "key_skills": "Know how to test steel",
        "salary": 46846,
        "euro_salary": null,
        "relevance_score": null,
        "currency": "EUR",
        "start_slot": "2023-11-25T19:16:00.000Z",
        "longitude": 8.481806785769917,
        "latitude": 47.367760717337184,
        "country_code": "ch",
        "postal_code": "8063",
        "city": "Zurich",
        "address": "Läufeweg, Albisrieden, Kreis 9, Zurich, District Zurich, Zurich, 8063, Switzerland",
        "view_count": 0,
        "created_at": "2023-09-12T19:45:12.486Z",
        "updated_at": "2023-09-12T19:45:14.578Z",
        "applications_count": 0,
        "employer_rating": 0,
        "job_notifications": "1",
        "boost": 0,
        "cv_required": false,
        "job_value": "01010000A0E6100000BDDB7EC812AF4740CFBE0761AFF620400000000000003040",
        "allowed_cv_format": [
            ".pdf",
            ".docx",
            ".txt",
            ".xml"
        ],
        "image_url": "https://f005.backblazeb2.com/file/TestEmbloy/ckhsa26ppx459de98a5pnb7h4s2s?Authorization=3_20231001141914_068232b8cf0d9dfd5ea4fd24_5bd6bad174d254fc44f52ad1648d9d546cde1a54_005_20231008141914_0028_dnld"
    }
}
```

---

## 7. Endpoint

PATCH: http://localhost:3000/api/v0/jobs?id=66

### Functionality

Updates a job given an id.

### Requestheader

```
access_token: ...
```

### Requestbody (form-data)

```
title:TestTitle
job_type:Retail
start_slot:2023-06-24T13:49:42.451Z
position:CEO
key_skills:Entrepreneurship
duration:9
salary:9
description:<div>Hier steht die Desription</div>
status:public
longitude:11.613942994844358
latitude:48.1951076
job_notifications:1
currency:EUR
image_url: <file>
```

---

## 8. Endpoint

GET: http://localhost:3000/api/v0/jobs?longitude=-0.1293754&latitude=51.5207794

### Functionality

Fetches feed.

### Requestheader

```
access_token: ...
```

### Responsebody

```
{
    "feed": [
        {
            ...
        },
        {
            ...
        }
    ]
}
```

---

## 9. Endpoint

GET: http://localhost:3000/api/v0/find?query=searchtest&job_type=Retail&sort_by=date_desc

### Functionality

Queries job based on query text ('query='), job_type ('job_type=') and sorts result ('sort_by=').
Valid values:
'query=<String>'
'job_type=<Job category e.g., retail, healthcare, food, ...>'
'sort_by=<date_desc, date_asc, salary_desc, salary_asc>'

If no job_type is present, it returns the query for all job_types; if sort_by is empty, it automatically sorts the
result by relevance (=matching the query)

### Requestheader

```
access_token: ...
```

### Responsebody

```
{
    "jobs": [
        {
            ...
        },
        {
            ...
        }
    ]
}
```

---

## 10. Endpoint

GET: http://localhost:3000/api/v0/maps?longitude=0&latitude=0

### Functionality

Returns job map (= jobs near the user's position: 'longitude', 'latitude')

### Requestheader

```
access_token: ...
```

### Responsebody

```
{
    "jobs": [
        {
            ...
        },
        {
            ...
        }
    ]
}
```

---

## 11. Endpoint

GET: http://localhost:3000/api/v0/jobs/66/applications

### Functionality

Fetches all applications for a given job.

### Requestheader

```
access_token: ...
```

### Responsebody

```
{
    "applications": [
        {
            ...
        },
        {
            ...
        }
    ]
}
```

---

## 12. Endpoint

GET: http://localhost:3000/api/v0/jobs/39/application

### Functionality

Fetches a single application for a given job (here job 39) and user (here 37; id contained in token).
Is called whenever user clicks on a job he applied to and wants to check his submitted application.

### Requestheader

```
access_token: ...
```

### Responsebody

```
{
    "application": [
        {
            "job_id": 39,
            "user_id": 37,
            "updated_at": "2023-10-01T14:52:40.288Z",
            "created_at": "2023-10-01T14:52:40.288Z",
            "status": "0",
            "application_text": "Hello World",
            "application_documents": "empty",
            "response": "No response yet ..."
        }
    ]
}
```

---

## 13. Endpoint

PATCH: http://localhost:3000/api/v0/jobs/39/applications/37/accept

### Functionality

Accepts an applications for a given job.

### Requestheader

```
access_token: ...
```

### Requestbody

```
{
    "response": "Good job!"
}

### Responsebody
{
    "message": "Application successfully accepted."
}
```

---

## 14. Endpoint

PATCH: http://localhost:3000/api/v0/jobs/39/applications/37/reject

### Functionality

Rejects an application for a given job.

### Requestheader

```
access_token: ...
```

### Requestbody

```
{
    "response": "Not good enough!"
}

### Responsebody (200 OK)
{
    "message": "Application successfully rejected."
}
```

---

## 15. Endpoint

POST: http://localhost:3000/api/v0/jobs/38/applications

### Functionality

Submits an application for a given job.

### Requestheader

```
access_token: ...
```

### Requestbody (form-data)

```
application_text:HelloWorld
application_attachmetn: <file, if needed and according to the file format specified in the given job>
```

### Responsebody (200 OK)

```
{
    "message": "Application submitted!"
}
```

---

## 16. Endpoint

DELETE: http://localhost:3000/api/v0/user/image

### Functionality

Removes the user's profile image.

### Requestheader

```
access_token: ...
```

### Responsebody (200 OK)

```
...TODO
```

---

## 17. Endpoint

PATCH: http://localhost:3000/api/v0/user/preferences

### Functionality

Updates the user's preferences.

### Requestheader

```
access_token: ...
```

### Requestbody

```
...TODO
```

### Responsebody (200 OK)

```
...TODO
```
