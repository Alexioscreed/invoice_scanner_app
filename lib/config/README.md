# Configuration Guide

## AppConfig Setup for Physical Device Testing

The `AppConfig` class in `lib/config/app_config.dart` is configured for physical device testing only.

### Configuration Setup
1. **Find your computer's IP address**:
   - Windows: `ipconfig` (look for IPv4 Address)
   - macOS/Linux: `ifconfig` or `ip addr show`

2. **Update the IP in AppConfig**:
   ```dart
   static const String serverIP = '192.168.1.125'; // Update this to your IP
   ```

3. **Ensure your backend is accessible**:
   - Backend should be running on `http://YOUR_IP:8080`
   - Firewall should allow connections on port 8080
   - Both devices should be on the same network

### Backend Configuration
- **Port**: 8080 (Spring Boot default)
- **Base URL**: `http://YOUR_IP:8080/api`
- **Network**: Same WiFi network as your device

### Network Configuration
- **Connection Timeout**: 15 seconds
- **Receive Timeout**: 30 seconds  
- **Send Timeout**: 30 seconds
- **Retry Attempts**: 3 with 2-second delay

### Debug Features
- **Debug Logs**: Enabled in development
- **Network Logging**: Detailed request/response logs
- **Configuration Printing**: Shows current config on app start

### Troubleshooting
1. **Can't connect from physical device**:
   - Check IP address in `serverIP`
   - Verify backend is running on port 8080
   - Check firewall settings (allow port 8080)
   - Ensure same WiFi network
   - Test backend URL in browser: `http://YOUR_IP:8080/api`

2. **Backend not accessible**:
   - Start Spring Boot backend
   - Check if running on correct port (8080)
   - Test locally: `http://localhost:8080/api`

3. **Debugging network issues**:
   - Check debug logs in console
   - Verify API endpoints are correct
   - Test backend URLs in browser first
   - Use network debugging tools

### Production Configuration
For production builds:
- Update `serverIP` to your production server
- Set `enableDebugLogs = false`
- Configure proper SSL certificates (HTTPS)
- Update timeouts as needed
- Use environment variables for sensitive data
