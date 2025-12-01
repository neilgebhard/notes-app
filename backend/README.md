# Backend Lambda Functions

## Structure

```
backend/
├── src/
│   ├── get-notes/       # GET /notes
│   ├── create-note/     # POST /notes
│   ├── update-note/     # PUT /notes/{id}
│   └── delete-note/     # DELETE /notes/{id}
├── dist/                # Built Lambda deployment packages
└── layers/              # Lambda layers for dependencies
```

## Database Schema

```sql
CREATE TABLE notes (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notes_user_id ON notes(user_id);
```

## Build & Deploy

```bash
# Install dependencies
npm install

# Build Lambda packages
npm run build

# Deploy (builds + applies Terraform)
npm run deploy
```

## Local Development

For local testing, you can use SAM or Lambda runtime emulators.

## Environment Variables

Each Lambda function receives:
- `DB_SECRET_ARN` - Secrets Manager ARN for DB credentials
- `ATTACHMENTS_BUCKET` - S3 bucket name for file storage
- `NODE_ENV` - Environment (dev/staging/prod)
