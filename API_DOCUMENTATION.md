# 📚 API Documentation - Gajayana Kost

**Base URL:** ``

**Authentication:** Bearer Token (Laravel Sanctum)

- Setelah login/register, gunakan token yang diterima di header: `Authorization: Bearer {token}`

---

## 📋 Table of Contents

1. [Public Endpoints (No Auth)](#public-endpoints-no-auth)
2. [Authentication Endpoints](#authentication-endpoints)
3. [Kos Endpoints (Public)](#kos-endpoints-public)
4. [Society Endpoints](#society-endpoints)
5. [Owner Endpoints](#owner-endpoints)
6. [Testing Examples](#testing-examples)

---

## 🔓 Public Endpoints (No Auth)

### 1. Health Check

**GET** `/health`

**Description:** Check if API is running

**Request:**

```bash
curl -X GET https://backend-gajayana-kost/api/health
```

**Response:**

```json
{
  "status": "ok",
  "message": "API is running",
  "timestamp": "2025-11-13T16:00:00.000000Z"
}
```

---

### 2. Test Endpoint

**GET** `/test`

**Description:** Test endpoint without database

**Request:**

```bash
curl -X GET https://backend-gajayana-kost/api/test
```

**Response:**

```json
{
  "status": "ok",
  "message": "Test endpoint working",
  "app_name": "Gajayana Kost",
  "environment": "production"
}
```

---

## 🔐 Authentication Endpoints

### 1. Register

**POST** `/auth/register`

**Description:** Register new user

**Request Body:**

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "phone": "081234567890",
  "role": "society"
}
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "phone": "081234567890",
    "role": "society"
  }'
```

**Postman Request (JSON Body):**

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "phone": "081234567890",
  "role": "society"
}
```

**Response (201):**

```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "081234567890",
      "role": "society"
    },
    "token": "1|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  }
}
```

---

### 2. Login

**POST** `/auth/login`

**Description:** Login user

**Request Body:**

```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

**Postman Request (JSON Body):**

```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "society"
    },
    "token": "2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  }
}
```

---

### 3. Check Email

**POST** `/auth/check-email`

**Description:** Check if email exists

**Request Body:**

```json
{
  "email": "john@example.com"
}
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/auth/check-email \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com"
  }'
```

**Postman Request (JSON Body):**

```json
{
  "email": "john@example.com"
}
```

**Response (200):**

```json
{
  "exists": true
}
```

---

### 4. Reset Password

**POST** `/auth/reset-password`

**Description:** Reset user password

**Request Body:**

```json
{
  "email": "john@example.com",
  "password": "newpassword123",
  "password_confirmation": "newpassword123",
  "token": "reset_token_here"
}
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "newpassword123",
    "password_confirmation": "newpassword123",
    "token": "reset_token_here"
  }'
```

**Postman Request (JSON Body):**

```json
{
  "email": "john@example.com",
  "password": "newpassword123",
  "password_confirmation": "newpassword123",
  "token": "reset_token_here"
}
```

---

### 5. Get Current User (Protected)

**GET** `/auth/user`

**Description:** Get authenticated user profile

**Headers:**

```
Authorization: Bearer {token}
```

**cURL Example:**

```bash
curl -X GET https://backend-gajayana-kost/api/auth/user \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "081234567890",
    "role": "society",
    "avatar": null
  }
}
```

---

### 6. Update Profile (Protected)

**POST** `/auth/profile`

**Description:** Update user profile

**Headers:**

```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Request Body (Form Data):**

```
name: John Doe Updated
phone: 081234567891
avatar: [file] (optional)
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/auth/profile \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -F "name=John Doe Updated" \
  -F "phone=081234567891" \
  -F "avatar=@/path/to/image.jpg"
```

**Response (200):**

```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": 1,
    "name": "John Doe Updated",
    "email": "john@example.com",
    "phone": "081234567891",
    "avatar": "storage/avatars/xxxxx.jpg"
  }
}
```

---

### 7. Change Password (Protected)

**POST** `/auth/change-password`

**Description:** Change user password

**Headers:**

```
Authorization: Bearer {token}
```

**Request Body:**

```json
{
  "current_password": "password123",
  "new_password": "newpassword123",
  "new_password_confirmation": "newpassword123"
}
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/auth/change-password \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "current_password": "password123",
    "new_password": "newpassword123",
    "new_password_confirmation": "newpassword123"
  }'
```

**Postman Request (JSON Body):**

```json
{
  "current_password": "password123",
  "new_password": "newpassword123",
  "new_password_confirmation": "newpassword123"
}
```

---

### 8. Logout (Protected)

**POST** `/auth/logout`

**Description:** Logout user (revoke token)

**Headers:**

```
Authorization: Bearer {token}
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/auth/logout \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Response (200):**

```json
{
  "success": true,
  "message": "Logout successful"
}
```

---

## 🏠 Kos Endpoints (Public)

### 1. Get All Kos

**GET** `/kos`

**Description:** Get paginated list of kos with filters

**Query Parameters:**

- `page` (optional): Page number (default: 1)
- `gender` (optional): Filter by gender (`all`, `male`, `female`, `mixed`)
- `search` (optional): Search by name or address
- `min_price` (optional): Minimum price
- `max_price` (optional): Maximum price
- `sort_by` (optional): Sort by (`price_low`, `price_high`, `popular`, `created_at`)
- `per_page` (optional): Items per page (default: 10)

**cURL Example:**

```bash
curl -X GET "https://backend-gajayana-kost/api/kos?page=1&gender=male&sort_by=price_low"
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "name": "Gajayana Kost",
        "address": "JL. Gajayana No. 8",
        "description": "Kos nyaman dan strategis",
        "price_per_month": 500000,
        "average_rating": 4.5,
        "gender": "male",
        "images": [
          {
            "id": 1,
            "file": "kos/xxxxx.jpg"
          }
        ],
        "facilities": [
          {
            "id": 1,
            "facility": "AC"
          }
        ]
      }
    ],
    "last_page": 5,
    "per_page": 10,
    "total": 50
  }
}
```

---

### 2. Get Kos Detail

**GET** `/kos/{id}`

**Description:** Get detailed information of a kos

**cURL Example:**

```bash
curl -X GET https://backend-gajayana-kost/api/kos/1
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Gajayana Kost",
    "address": "JL. Gajayana No. 8",
    "description": "Kos nyaman dan strategis",
    "price_per_month": 500000,
    "average_rating": 4.5,
    "gender": "male",
    "whatsapp_number": "081234567890",
    "latitude": -7.9778,
    "longitude": 112.6308,
    "images": [...],
    "facilities": [...],
    "rooms": [...],
    "payment_methods": [...],
    "reviews": [...],
    "owner": {
      "id": 1,
      "name": "Owner Name",
      "phone": "081234567890"
    }
  }
}
```

---

## 👥 Society Endpoints (Protected - Role: Society)

### 1. Get My Bookings

**GET** `/bookings`

**Description:** Get all bookings for authenticated society user

**Headers:**

```
Authorization: Bearer {token}
```

**cURL Example:**

```bash
curl -X GET https://backend-gajayana-kost/api/bookings \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Response (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "kos_id": 1,
      "room_id": 1,
      "booking_code": "KH-2025-001",
      "start_date": "2025-11-10",
      "end_date": "2025-12-10",
      "total_price": 500000,
      "status": "pending",
      "kos": {
        "id": 1,
        "name": "Gajayana Kost",
        "address": "JL. Gajayana No. 8"
      },
      "room": {
        "id": 1,
        "room_number": "A1",
        "room_type": "single"
      }
    }
  ]
}
```

---

### 2. Create Booking

**POST** `/bookings`

**Description:** Create new booking

**Headers:**

```
Authorization: Bearer {token}
```

**Request Body:**

```json
{
  "kos_id": 1,
  "room_id": 1,
  "start_date": "2025-11-15",
  "end_date": "2025-12-15"
}
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/bookings \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "kos_id": 1,
    "room_id": 1,
    "start_date": "2025-11-15",
    "end_date": "2025-12-15"
  }'
```

**Postman Request (JSON Body):**

```json
{
  "kos_id": 1,
  "room_id": 1,
  "start_date": "2025-11-15",
  "end_date": "2025-12-15"
}
```

**Response (201):**

```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "id": 1,
    "booking_code": "KH-2025-001",
    "status": "pending",
    "total_price": 500000
  }
}
```

---

### 3. Get Booking Detail

**GET** `/bookings/{id}`

**Description:** Get booking detail

**Headers:**

```
Authorization: Bearer {token}
```

**cURL Example:**

```bash
curl -X GET https://backend-gajayana-kost/api/bookings/1 \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

---

### 4. Add Review

**POST** `/kos/{kos_id}/reviews`

**Description:** Add review to a kos

**Headers:**

```
Authorization: Bearer {token}
```

**Request Body:**

```json
{
  "rating": 5,
  "comment": "Kos sangat nyaman dan strategis!"
}
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/kos/1/reviews \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "comment": "Kos sangat nyaman dan strategis!"
  }'
```

**Postman Request (JSON Body):**

```json
{
  "rating": 5,
  "comment": "Kos sangat nyaman dan strategis!"
}
```

---

### 5. Update Review

**PUT** `/reviews/{id}`

**Description:** Update existing review

**Headers:**

```
Authorization: Bearer {token}
```

**Request Body:**

```json
{
  "rating": 4,
  "comment": "Updated comment"
}
```

**cURL Example:**

```bash
curl -X PUT https://backend-gajayana-kost/api/reviews/1 \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 4,
    "comment": "Updated comment"
  }'
```

**Postman Request (JSON Body):**

```json
{
  "rating": 4,
  "comment": "Updated comment"
}
```

---

### 6. Delete Review

**DELETE** `/reviews/{id}`

**Description:** Delete review

**Headers:**

```
Authorization: Bearer {token}
```

**cURL Example:**

```bash
curl -X DELETE https://backend-gajayana-kost/api/reviews/1 \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

---

### 7. Get Favorites

**GET** `/favorites`

**Description:** Get user's favorite kos

**Headers:**

```
Authorization: Bearer {token}
```

**cURL Example:**

```bash
curl -X GET https://backend-gajayana-kost/api/favorites \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

---

### 8. Add Favorite

**POST** `/favorites`

**Description:** Add kos to favorites

**Headers:**

```
Authorization: Bearer {token}
```

**Request Body:**

```json
{
  "kos_id": 1
}
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/favorites \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "kos_id": 1
  }'
```

**Postman Request (JSON Body):**

```json
{
  "kos_id": 1
}
```

---

### 9. Remove Favorite

**DELETE** `/favorites/{id}`

**Description:** Remove kos from favorites

**Headers:**

```
Authorization: Bearer {token}
```

**cURL Example:**

```bash
curl -X DELETE https://backend-gajayana-kost/api/favorites/1 \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

---

## 🏢 Owner Endpoints (Protected - Role: Owner)

### 1. Get My Kos

**GET** `/owner/kos`

**Description:** Get all kos owned by authenticated owner

**Headers:**

```
Authorization: Bearer {token}
```

**cURL Example:**

```bash
curl -X GET https://backend-gajayana-kost/api/owner/kos \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Response (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Gajayana Kost",
      "address": "JL. Gajayana No. 8",
      "price_per_month": 500000,
      "facilities": [...],
      "payment_methods": [...],
      "rooms": [...],
      "rooms_count": 5,
      "bookings_count": 10,
      "reviews_count": 3
    }
  ]
}
```

---

### 2. Create Kos

**POST** `/owner/kos`

**Description:** Create new kos

**Headers:**

```
Authorization: Bearer {token}
```

**Request Body:**

```json
{
  "name": "New Kos",
  "address": "JL. Example No. 123",
  "description": "Kos baru yang nyaman",
  "price_per_month": 600000,
  "gender": "all",
  "whatsapp_number": "081234567890",
  "latitude": -7.9778,
  "longitude": 112.6308,
  "facilities": ["AC", "Kamar Mandi Dalam", "Laundry"],
  "payment_methods": ["Cash", "Transfer", "OVO"]
}
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/owner/kos \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Kos",
    "address": "JL. Example No. 123",
    "description": "Kos baru yang nyaman",
    "price_per_month": 600000,
    "gender": "all",
    "whatsapp_number": "081234567890",
    "latitude": -7.9778,
    "longitude": 112.6308,
    "facilities": ["AC", "Kamar Mandi Dalam", "Laundry"],
    "payment_methods": ["Cash", "Transfer", "OVO"]
  }'
```

**Postman Request (JSON Body):**

```json
{
  "name": "New Kos",
  "address": "JL. Example No. 123",
  "description": "Kos baru yang nyaman",
  "price_per_month": 600000,
  "gender": "all",
  "whatsapp_number": "081234567890",
  "latitude": -7.9778,
  "longitude": 112.6308,
  "facilities": ["AC", "Kamar Mandi Dalam", "Laundry"],
  "payment_methods": ["Cash", "Transfer", "OVO"]
}
```

---

### 3. Get Kos Detail (Owner)

**GET** `/owner/kos/{id}`

**Description:** Get detailed kos information (owner only)

**Headers:**

```
Authorization: Bearer {token}
```

**cURL Example:**

```bash
curl -X GET https://backend-gajayana-kost/api/owner/kos/1 \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

---

### 4. Update Kos

**PUT** `/owner/kos/{id}`

**Description:** Update kos information

**Headers:**

```
Authorization: Bearer {token}
```

**Request Body:**

```json
{
  "name": "Updated Kos Name",
  "address": "Updated Address",
  "description": "Updated description",
  "price_per_month": 700000,
  "gender": "male",
  "facilities": ["AC", "Kamar Mandi Dalam", "TV"],
  "payment_methods": ["Cash", "Transfer", "QRIS"]
}
```

**cURL Example:**

```bash
curl -X PUT https://backend-gajayana-kost/api/owner/kos/1 \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Kos Name",
    "address": "Updated Address",
    "description": "Updated description",
    "price_per_month": 700000,
    "gender": "male",
    "facilities": ["AC", "Kamar Mandi Dalam", "TV"],
    "payment_methods": ["Cash", "Transfer", "QRIS"]
  }'
```

**Postman Request (JSON Body):**

```json
{
  "name": "Updated Kos Name",
  "address": "Updated Address",
  "description": "Updated description",
  "price_per_month": 700000,
  "gender": "male",
  "facilities": ["AC", "Kamar Mandi Dalam", "TV"],
  "payment_methods": ["Cash", "Transfer", "QRIS"]
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Kos updated successfully",
  "data": {
    "id": 1,
    "name": "Updated Kos Name",
    ...
  }
}
```

---

### 5. Delete Kos

**DELETE** `/owner/kos/{id}`

**Description:** Delete kos

**Headers:**

```
Authorization: Bearer {token}
```

**cURL Example:**

```bash
curl -X DELETE https://backend-gajayana-kost/api/owner/kos/1 \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

---

### 6. Add Rooms to Kos

**POST** `/owner/kos/{id}/rooms`

**Description:** Add rooms to kos

**Headers:**

```
Authorization: Bearer {token}
```

**Request Body:**

```json
{
  "rooms": [
    {
      "room_number": "A1",
      "room_type": "single",
      "price": 500000
    },
    {
      "room_number": "A2",
      "room_type": "double",
      "price": 800000
    }
  ]
}
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/owner/kos/1/rooms \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "rooms": [
      {
        "room_number": "A1",
        "room_type": "single",
        "price": 500000
      }
    ]
  }'
```

**Postman Request (JSON Body):**

```json
{
  "rooms": [
    {
      "room_number": "A1",
      "room_type": "single",
      "price": 500000
    },
    {
      "room_number": "A2",
      "room_type": "double",
      "price": 800000
    }
  ]
}
```

---

### 7. Upload Kos Images

**POST** `/owner/kos/{id}/images`

**Description:** Upload images for kos

**Headers:**

```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Request Body (Form Data):**

```
images[]: [file1]
images[]: [file2]
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/owner/kos/1/images \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -F "images[]=@/path/to/image1.jpg" \
  -F "images[]=@/path/to/image2.jpg"
```

---

### 8. Get Owner Bookings

**GET** `/owner/bookings`

**Description:** Get all bookings for owner's kos

**Headers:**

```
Authorization: Bearer {token}
```

**cURL Example:**

```bash
curl -X GET https://backend-gajayana-kost/api/owner/bookings \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

---

### 9. Update Booking Status

**PUT** `/owner/bookings/{id}/status`

**Description:** Update booking status (accept/reject)

**Headers:**

```
Authorization: Bearer {token}
```

**Request Body:**

```json
{
  "status": "accept",
  "rejected_reason": null
}
```

**cURL Example:**

```bash
curl -X PUT https://backend-gajayana-kost/api/owner/bookings/1/status \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "accept"
  }'
```

**Postman Request (JSON Body):**

```json
{
  "status": "accept",
  "rejected_reason": null
}
```

**Untuk reject:**

```json
{
  "status": "reject",
  "rejected_reason": "Kamar sudah penuh"
}
```

---

### 10. Get Reviews

**GET** `/owner/reviews`

**Description:** Get all reviews for owner's kos

**Headers:**

```
Authorization: Bearer {token}
```

**cURL Example:**

```bash
curl -X GET https://backend-gajayana-kost/api/owner/reviews \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

---

### 11. Reply to Review

**POST** `/owner/reviews/{id}/reply`

**Description:** Reply to a review

**Headers:**

```
Authorization: Bearer {token}
```

**Request Body:**

```json
{
  "reply": "Terima kasih atas reviewnya!"
}
```

**cURL Example:**

```bash
curl -X POST https://backend-gajayana-kost/api/owner/reviews/1/reply \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "reply": "Terima kasih atas reviewnya!"
  }'
```

**Postman Request (JSON Body):**

```json
{
  "reply": "Terima kasih atas reviewnya!"
}
```

---

### 12. Get Analytics

**GET** `/owner/analytics`

**Description:** Get owner analytics (total kos, bookings, revenue, ratings)

**Headers:**

```
Authorization: Bearer {token}
```

**cURL Example:**

```bash
curl -X GET https://backend-gajayana-kost/api/owner/analytics \
  -H "Authorization: Bearer 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "overview": {
      "total_kos": 4,
      "total_bookings": 10,
      "total_revenue": 5000000,
      "pending_count": 2,
      "accepted_count": 7,
      "rejected_count": 1,
      "avg_rating": 4.5,
      "total_reviews": 15
    },
    "monthly_stats": [...]
  }
}
```

---

## 🧪 Testing Examples

### Complete Flow Example

#### 1. Register as Society User

```bash
curl -X POST https://backend-gajayana-kost/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "phone": "081234567890",
    "role": "society"
  }'
```

**Save the token from response!**

#### 2. Login

```bash
curl -X POST https://backend-gajayana-kost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

#### 3. Get All Kos

```bash
curl -X GET "https://backend-gajayana-kost/api/kos?page=1&gender=male"
```

#### 4. Get Kos Detail

```bash
curl -X GET https://backend-gajayana-kost/api/kos/1
```

#### 5. Create Booking (with token)

```bash
curl -X POST https://backend-gajayana-kost/api/bookings \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "kos_id": 1,
    "room_id": 1,
    "start_date": "2025-11-15",
    "end_date": "2025-12-15"
  }'
```

---

## 📝 Notes

1. **Authentication:** Most endpoints require Bearer token authentication
2. **Role-based Access:** Some endpoints are restricted to specific roles (society/owner)
3. **Pagination:** List endpoints support pagination with `page` and `per_page` parameters
4. **File Uploads:** Use `multipart/form-data` for endpoints that accept file uploads
5. **Error Responses:** All errors follow this format:
   ```json
   {
     "success": false,
     "message": "Error message here"
   }
   ```

---

## 🔗 Base URLs

- **API Base URL:** `https://backend-gajayana-kost/api`
- **Storage Base URL:** `https://backend-gajayana-kost/storage`

---

**Last Updated:** November 13, 2025
