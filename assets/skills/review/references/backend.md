# Backend Review Lens

Use when the diff touches an endpoint, service, transport, or persistence boundary.

## Authoring

1. Define request and response schemas at the transport boundary before handler logic.
2. Keep route handlers thin: validate input, invoke a domain service, map the result.
3. Keep business logic and queries in pure service functions decoupled from `Request` and `Response`.
4. Map domain errors to semantic status codes with one uniform error envelope.
5. Pass timeout signals to external I/O, validate environment variables on boot, and close pools on shutdown.

## Review checks

- Is every input validated at the edge, including query and path parameters?
- Is the handler free of database queries and business algorithms?
- Are stack traces, database errors, and credentials kept out of client responses?
- Do all failure branches return the same error shape?
- Are timeouts, idempotency, retries, and pool shutdown explicit?
- Do tests exercise the seam rather than HTTP mocks of the implementation?

## Pattern

```typescript
export const CreateUserSchema = z.object({
  email: z.string().email(),
  displayName: z.string().min(2).max(50),
});

export async function createUser(
  input: z.infer<typeof CreateUserSchema>,
  deps: { userRepo: UserRepository },
): Promise<Result<User, UserCreationError>> {
  const existing = await deps.userRepo.findByEmail(input.email);
  if (existing) return Result.err(new ConflictError("User already exists"));
  return Result.ok(await deps.userRepo.insert(input));
}

export async function POST(req: Request, ctx: AppContext): Promise<Response> {
  const parsed = CreateUserSchema.safeParse(await req.json());
  if (!parsed.success) return jsonError(422, "Invalid payload", parsed.error.flatten());
  const result = await createUser(parsed.data, ctx);
  return result.ok ? jsonResponse(201, result.val) : mapDomainErrorToResponse(result.error);
}
```

## Verify

Endpoint tests cover valid input, invalid payloads (400/422), expected domain errors, timeout behavior, and clean shutdown.
