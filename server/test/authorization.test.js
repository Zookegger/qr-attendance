import request from "supertest";
import assert from "node:assert";
import app from "../src/app.ts";
import { sequelize } from "../src/config/database.ts";
import { User } from "../src/models/index.ts";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "your_jwt_secret_key";

describe("Authorization System Tests", () => {
	before(async () => {
		// Sync database before running tests
		await sequelize.sync({ force: true });
	});

	beforeEach(async () => {
		// Clear users before each test
		await User.destroy({ where: {} });
	});

	const createTestUser = async (role = "user") => {
		const passwordHash = await bcrypt.hash("password123", 10);
		return await User.create({
			name: `Test ${role}`,
			email: `${role}@example.com`,
			password_hash: passwordHash,
			role: role,
		});
	};

	const generateToken = (user) => {
		return jwt.sign({ id: user.id, role: user.role }, JWT_SECRET, {
			expiresIn: "1h",
		});
	};

	describe("Authentication Middleware", () => {
		it("should return 401 if Authorization header is missing", async () => {
			await request(app)
				.get("/api/auth/me")
				.expect(401)
				.expect((res) => {
					assert.strictEqual(
						res.body.message,
						"Authorization header missing",
					);
				});
		});

		it("should return 401 if token is missing in Authorization header", async () => {
			await request(app)
				.get("/api/auth/me")
				.set("Authorization", "Bearer ")
				.expect(401)
				.expect((res) => {
					assert.strictEqual(res.body.message, "Token missing");
				});
		});

		it("should return 401 if token is invalid", async () => {
			await request(app)
				.get("/api/auth/me")
				.set("Authorization", "Bearer invalidtoken")
				.expect(401)
				.expect((res) => {
					assert.strictEqual(res.body.message, "Invalid token");
				});
		});

		it("should return 401 if user does not exist", async () => {
			const token = jwt.sign(
				{ id: "non-existent-id", role: "user" },
				JWT_SECRET,
			);
			await request(app)
				.get("/api/auth/me")
				.set("Authorization", `Bearer ${token}`)
				.expect(401)
				.expect((res) => {
					assert.strictEqual(res.body.message, "User not found");
				});
		});

		it("should allow access with valid token", async () => {
			const user = await createTestUser("user");
			const token = generateToken(user);

			await request(app)
				.get("/api/auth/me")
				.set("Authorization", `Bearer ${token}`)
				.expect(200)
				.expect((res) => {
					assert.strictEqual(res.body.email, user.email);
				});
		});
	});

	describe("Authorization Middleware (Role-based)", () => {
		it("should allow admin to access admin routes", async () => {
			const admin = await createTestUser("admin");
			const token = generateToken(admin);

			// Assuming /api/admin/config is a valid admin route
			// We might get 404 if config doesn't exist, or 200 if it does.
			// But we shouldn't get 401 or 403.
			// Let's check the response status. If it's not 401/403, auth passed.
			// Based on routes, it calls AdminController.getOfficeConfig

			const res = await request(app)
				.get("/api/admin/config")
				.set("Authorization", `Bearer ${token}`);

			assert.notStrictEqual(res.status, 401);
			assert.notStrictEqual(res.status, 403);
		});

		it("should deny user from accessing admin routes", async () => {
			const user = await createTestUser("user");
			const token = generateToken(user);

			await request(app)
				.get("/api/admin/config")
				.set("Authorization", `Bearer ${token}`)
				.expect(403)
				.expect((res) => {
					assert.strictEqual(res.body.message, "Forbidden");
				});
		});
	});
});
