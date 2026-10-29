# Modular Design & Seam Principles

## Vertical Slice Structure
```
src/
  features/
    channels/
      channel-routes.ts      # HTTP transport
      channel-service.ts     # Domain logic
      channel-repository.ts  # Database queries
      channel-types.ts       # Domain models & schemas
    auth/
      auth-routes.ts
      auth-service.ts
      auth-types.ts
  composition-root.ts        # Wires DB, repositories, services, and routes together
```

## Inverted Seam (Port & Adapter)
```typescript
// In domain (ports):
export interface UserRepository {
  findById(id: UserId): Promise<User | null>;
  save(user: User): Promise<void>;
}

// In infrastructure (adapters):
export class PostgresUserRepository implements UserRepository {
  constructor(private readonly db: DatabaseClient) {}
  async findById(id: UserId): Promise<User | null> {
    const row = await this.db.query("SELECT * FROM users WHERE id = $1", [id]);
    return row ? toDomainUser(row) : null;
  }
  async save(user: User): Promise<void> {
    await this.db.query("INSERT INTO users ...", [...]);
  }
}
```
