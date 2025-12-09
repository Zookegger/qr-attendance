import request from "supertest";
import app from "../src/app.ts";

describe("GET /api/health", () => {
	it("should return status OK", (done) => {
		request(app)
			.get("/api/health")
			.expect(200)
			.expect((res) => {
				if (res.body.status !== "UP")
					throw new Error("Response does not match");
			})
			.end(done);
	});
});
