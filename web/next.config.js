/** @type {import('next').NextConfig} */
const nextConfig = {
  // standalone output — bắt buộc cho Docker image nhỏ gọn (Day 2-3)
  output: "standalone",
  env: {
    // API base URL — server-side calls dùng tên service trong docker network
    API_INTERNAL_URL: process.env.API_INTERNAL_URL || "http://api:8000",
  },
};

module.exports = nextConfig;
