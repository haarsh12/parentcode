"""
Database Connection Diagnostic Tool
Run this to test your Supabase connection
"""
import socket
import sys
from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

print("=" * 70)
print("SUPABASE CONNECTION DIAGNOSTIC")
print("=" * 70)

# Extract host and port from DATABASE_URL
if DATABASE_URL:
    # Parse the URL
    if "://" in DATABASE_URL:
        parts = DATABASE_URL.split("://")[1]
        if "@" in parts:
            host_part = parts.split("@")[1]
            if ":" in host_part:
                host = host_part.split(":")[0]
                port_part = host_part.split(":")[1]
                port = int(port_part.split("/")[0])
            else:
                host = host_part.split("/")[0]
                port = 5432
        else:
            host = parts.split(":")[0]
            port = 5432
    else:
        print("❌ Invalid DATABASE_URL format")
        sys.exit(1)
    
    print(f"\n📍 Target: {host}:{port}")
    print(f"📍 Full URL: {DATABASE_URL[:50]}...")
    
    # Test DNS resolution
    print(f"\n🔍 Testing DNS resolution...")
    try:
        ip_addresses = socket.getaddrinfo(host, port, socket.AF_UNSPEC, socket.SOCK_STREAM)
        print(f"✅ DNS resolved successfully:")
        for addr in ip_addresses[:3]:
            print(f"   - {addr[4][0]} (IPv{6 if ':' in addr[4][0] else 4})")
    except socket.gaierror as e:
        print(f"❌ DNS resolution failed: {e}")
        sys.exit(1)
    
    # Test port 5432
    print(f"\n🔌 Testing connection to port 5432...")
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)
    try:
        result = sock.connect_ex((host, 5432))
        if result == 0:
            print(f"✅ Port 5432 is OPEN and reachable")
        else:
            print(f"❌ Port 5432 is BLOCKED (error code: {result})")
            print(f"   This means your network/firewall is blocking PostgreSQL")
    except Exception as e:
        print(f"❌ Connection test failed: {e}")
    finally:
        sock.close()
    
    # Test port 6543 (connection pooler)
    print(f"\n🔌 Testing connection to port 6543 (pooler)...")
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)
    try:
        result = sock.connect_ex((host, 6543))
        if result == 0:
            print(f"✅ Port 6543 is OPEN and reachable")
            print(f"   💡 TIP: You can use the connection pooler!")
        else:
            print(f"❌ Port 6543 is BLOCKED (error code: {result})")
    except Exception as e:
        print(f"❌ Connection test failed: {e}")
    finally:
        sock.close()
    
    # Test HTTPS (port 443)
    print(f"\n🔌 Testing HTTPS connection (port 443)...")
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)
    try:
        result = sock.connect_ex((host, 443))
        if result == 0:
            print(f"✅ Port 443 is OPEN")
            print(f"   💡 Your network allows HTTPS but blocks PostgreSQL ports")
        else:
            print(f"❌ Port 443 is also blocked")
    except Exception as e:
        print(f"❌ Connection test failed: {e}")
    finally:
        sock.close()
    
    print("\n" + "=" * 70)
    print("RECOMMENDATIONS:")
    print("=" * 70)
    
    # Check if both PostgreSQL ports are blocked
    sock1 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock1.settimeout(3)
    port_5432_blocked = sock1.connect_ex((host, 5432)) != 0
    sock1.close()
    
    sock2 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock2.settimeout(3)
    port_6543_blocked = sock2.connect_ex((host, 6543)) != 0
    sock2.close()
    
    if port_5432_blocked and port_6543_blocked:
        print("\n❌ Both PostgreSQL ports (5432 and 6543) are BLOCKED")
        print("\n✅ SOLUTIONS:")
        print("   1. Connect via mobile hotspot (fastest)")
        print("   2. Use a VPN service")
        print("   3. Contact your ISP to unblock ports 5432 and 6543")
        print("   4. Check Supabase dashboard for IP restrictions:")
        print("      https://supabase.com/dashboard/project/yycyldkqlnothjojxtea/settings/database")
    elif not port_5432_blocked:
        print("\n✅ Port 5432 is working! Your connection should work.")
    elif not port_6543_blocked:
        print("\n✅ Port 6543 is working! Update your DATABASE_URL to use port 6543")
        print(f"   Change: ...supabase.co:5432/...")
        print(f"   To:     ...supabase.co:6543/...")
    
    print("\n" + "=" * 70)
else:
    print("❌ DATABASE_URL not found in .env file")
