package cof.oo;

import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
 
public class WindowsRegistry {
    
    /**
     * 
     * @param location path in the registry
     * @param key registry key
     * @return registry value or null if not found
     * @throws java.lang.Exception
     */
    public static final String readRegistry(String location, String key) throws Exception {
        try {
            // Run reg query, then read output with StreamReader (internal class)
            Process process = Runtime.getRuntime().exec("reg query " + 
                    '"'+ location + "\" /v " + key);
 
            StreamReader reader = new StreamReader(process.getInputStream());
            reader.start();
            process.waitFor();
            reader.join();
 
            // Parse out the value
            Pattern p = Pattern.compile("\"([^\"]+)\"");
            Matcher m = p.matcher(reader.getResult());

            if (m.find()) {
                return m.group(1);
            }
        } catch (Exception e) {
            throw e;
        }
 
        return null;
    }
 
    static class StreamReader extends Thread {
        private final InputStream is;
        private final StringWriter sw= new StringWriter();
 
        public StreamReader(InputStream is) {
            this.is = is;
        }
 
        @Override
        public void run() {
            try {
                int c;
                while ((c = is.read()) != -1) {
                    sw.write(c);
                }
            } catch (IOException e) { 
                
            }
        }
 
        public String getResult() {
            return sw.toString();
        }
    }

}