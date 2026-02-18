# Capturing All Output from IBM ACE Integration Server

## Problem
The command `IntegrationServer --work-dir /home/aceuser/ace-server --name ace-server > trace.txt` only captures stdout, missing Java verbose output and stderr.

## Solution: Capture ALL Output (Linux/Docker)

### 1. Basic: Capture stdout and stderr together
```bash
IntegrationServer --work-dir /home/aceuser/ace-server --name ace-server > trace.txt 2>&1
```

### 2. Advanced: Capture with Java Verbose Logging

Set environment variables before starting the Integration Server:

```bash
# Enable Java verbose output for classloading
export MQSI_JVMENV_EXTRA_OPTIONS="-verbose:class -verbose:gc -verbose:jni -XX:+PrintCommandLineFlags -XX:+PrintGCDetails"

# Alternative: More detailed classloader tracing
export MQSI_JVMENV_EXTRA_OPTIONS="-verbose:class -Xlog:class+load=info:file=/home/aceuser/ace-server/classloader.log"

# Run Integration Server with all output captured
IntegrationServer --work-dir /home/aceuser/ace-server --name ace-server > trace.txt 2>&1
```

### 3. Maximum Debugging: Capture Everything

```bash
# Set multiple Java debugging options
export MQSI_JVMENV_EXTRA_OPTIONS="-verbose:class -verbose:gc -verbose:jni -XX:+PrintCommandLineFlags -XX:+PrintGCDetails -XX:+TraceClassLoading -XX:+TraceClassUnloading"

# Enable ACE internal tracing
export BIP_TRACE_LEVEL=4

# Capture all output streams
IntegrationServer --work-dir /home/aceuser/ace-server --name ace-server > /home/aceuser/ace-server/trace_full.txt 2>&1
```

### 4. Separate stdout and stderr (for analysis)

```bash
IntegrationServer --work-dir /home/aceuser/ace-server --name ace-server > stdout.txt 2> stderr.txt
```

### 5. Capture to file AND see output in terminal

```bash
IntegrationServer --work-dir /home/aceuser/ace-server --name ace-server 2>&1 | tee trace.txt
```

## Java Verbose Options Explained

| Option | Description |
|--------|-------------|
| `-verbose:class` | Shows every class loaded by the JVM |
| `-verbose:gc` | Shows garbage collection details |
| `-verbose:jni` | Shows JNI (Java Native Interface) calls |
| `-XX:+PrintCommandLineFlags` | Shows JVM startup flags |
| `-XX:+PrintGCDetails` | Detailed GC information |
| `-XX:+TraceClassLoading` | Traces class loading (older JVMs) |
| `-Xlog:class+load=info` | Modern JVM class loading log |

## IBM ACE Specific Options

### Environment Variables

```bash
# Trace level (0-4, 4 is most verbose)
export BIP_TRACE_LEVEL=4

# Trace file location
export BIP_TRACE_FILE=/home/aceuser/ace-server/bip_trace.txt

# Java options for ACE
export MQSI_JVMENV_EXTRA_OPTIONS="-verbose:class -Xlog:class+load=info"
```

### Using server.conf.yaml

Add to `/home/aceuser/ace-server/server.conf.yaml`:

```yaml
Diagnostics:
  traceLevel: 4
  traceFile: /home/aceuser/ace-server/diagnostics.txt
```

## Complete Example for Docker/Linux

```bash
#!/bin/bash

# Set working directory
WORK_DIR=/home/aceuser/ace-server
SERVER_NAME=ace-server
OUTPUT_FILE=${WORK_DIR}/trace_complete.txt

# Enable maximum Java verbose output
export MQSI_JVMENV_EXTRA_OPTIONS="-verbose:class -verbose:gc -verbose:jni -XX:+PrintCommandLineFlags -XX:+PrintGCDetails -Xlog:class+load=info:file=${WORK_DIR}/classloader.log -Xlog:gc*:file=${WORK_DIR}/gc.log"

# Enable ACE tracing
export BIP_TRACE_LEVEL=4

# Start Integration Server with all output captured
echo "Starting Integration Server with full logging..."
echo "Output file: ${OUTPUT_FILE}"
echo "Classloader log: ${WORK_DIR}/classloader.log"
echo "GC log: ${WORK_DIR}/gc.log"

IntegrationServer --work-dir ${WORK_DIR} --name ${SERVER_NAME} > ${OUTPUT_FILE} 2>&1
```

## Verification

After starting the server, verify all logs are being captured:

```bash
# Check main trace file
tail -f /home/aceuser/ace-server/trace_complete.txt

# Check classloader log (if using -Xlog)
tail -f /home/aceuser/ace-server/classloader.log

# Check for Java verbose output in main trace
grep -i "loaded" /home/aceuser/ace-server/trace_complete.txt | head -20
```

## Key Points

1. **`2>&1`** is critical - it redirects stderr (file descriptor 2) to stdout (file descriptor 1)
2. **Order matters** - `> file 2>&1` is correct, `2>&1 > file` won't work as expected
3. **Java options** must be set via `MQSI_JVMENV_EXTRA_OPTIONS` before starting IntegrationServer
4. **Modern JVMs** (Java 9+) use `-Xlog:` syntax instead of older `-XX:+TraceClassLoading`
5. **File permissions** - ensure the aceuser has write access to output directories

## Troubleshooting

If you still don't see Java verbose output:

1. Verify environment variable is set:
   ```bash
   echo $MQSI_JVMENV_EXTRA_OPTIONS
   ```

2. Check if ACE is picking up the options:
   ```bash
   ps aux | grep IntegrationServer
   ```

3. Look for JVM startup messages in the trace file:
   ```bash
   grep -i "java\|jvm\|verbose" trace.txt | head -50
   ```

4. Try the `-Xlog` syntax for Java 17 (ACE 13 uses Java 17):
   ```bash
   export MQSI_JVMENV_EXTRA_OPTIONS="-Xlog:class+load=info,gc=debug:file=/home/aceuser/ace-server/jvm_verbose.log"