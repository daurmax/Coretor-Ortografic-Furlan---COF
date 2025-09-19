package cof.oo;


import com.sun.star.lib.uno.helper.ComponentBase;
import com.sun.star.uno.UnoRuntime;
import com.sun.star.lang.XMultiServiceFactory;
import com.sun.star.lang.XSingleServiceFactory;
import com.sun.star.linguistic2.XSpellChecker;
import com.sun.star.linguistic2.XLinguServiceEventBroadcaster;
import com.sun.star.lang.XInitialization;		
import com.sun.star.lang.XServiceInfo;		
import com.sun.star.lang.XServiceDisplayName;		
import com.sun.star.uno.RuntimeException;
import com.sun.star.lang.IllegalArgumentException;
import com.sun.star.linguistic2.XLinguServiceEventListener;
import com.sun.star.linguistic2.XSpellAlternatives;
import com.sun.star.linguistic2.SpellFailure;
import com.sun.star.lang.Locale;
import com.sun.star.beans.XPropertySet;
import com.sun.star.beans.PropertyValue;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.util.ArrayList;

import com.esotericsoftware.minlog.Log;
import com.sun.star.uno.AnyConverter;
import java.io.BufferedWriter;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.Writer;
import java.util.Date;


public class COFSpeller extends ComponentBase implements
        XSpellChecker,
        XLinguServiceEventBroadcaster,
        XInitialization,
        XServiceDisplayName,
        XServiceInfo
{    
    PropChgHelper_Spell         aPropChgHelper;
    ArrayList                   aEvtListeners;
    boolean                     bDisposing;
    
    
    private Process process = null;

    
    private BufferedReader outputStream = null;

    
    private PrintStream inputStream = null;

    
    private BufferedReader errorStream = null;
     
    
    
    public static final String CLIKEY="CLI"; 
    public static final String REGKEY="HKLM\\SOFTWARE\\CdIF scarl\\COF2"; 
                
    private static final boolean DEBUG = System.getProperty("COFDEBUG") != null;
    
    private boolean isInit=false; 
    
    static public class COFLogger extends Log.Logger {
        
        private static final String logFileName = "log_ooplugin.txt";
        private static final String LOG_DIR = "COF2"; 
        private static String logPath = null;
                
        @Override
        public void log (int level, String category, String message, Throwable ex) {
            if (logPath == null) {  
                String localDir = System.getenv("LOCALAPPDATA");
                if ((localDir != null) && !localDir.equals("") && (new File(localDir)).isDirectory()) {
                    File userCofDir = new File(localDir, LOG_DIR);
                    if (!userCofDir.exists()) {
                        if(!userCofDir.mkdir()) {
                            System.err.println("No rivi a creâ directory '"+userCofDir.getAbsolutePath()+"'");
                            return;
                        }
                    }
                    logPath = new File(userCofDir, logFileName).getAbsolutePath();
                } else {
                    System.err.println("No LOCALAPPDATA");
                    return;
                }
            }
            
            String row = String.format("%tc - %s [%s] %s\n", 
                    new Date(), level, category, message);
            if (ex != null) {
                StringWriter writer = new StringWriter(256);
                ex.printStackTrace(new PrintWriter(writer));
                row = row + writer.toString().trim() + "\n";
            }
            
            Writer writer = null;
            try {
                writer = new BufferedWriter(new OutputStreamWriter(
                      new FileOutputStream(logPath, true), "utf-8"));
                writer.write(row);
            } catch (Exception ex2) {
                System.err.println("No rivi a scrivi in file di log");
            } finally {
               if (writer != null) {
                   try {
                        writer.close();
                   } catch (Exception ex2) {}
               }
            }
        }
    }
    
    
    public COFSpeller() {
        
        Log.setLogger(new COFLogger());
        
        String[] aProps = new String[]
            {
                "IsSpellUpperCase",
            };
        aPropChgHelper  = new PropChgHelper_Spell( (XSpellChecker) this, aProps );
        aEvtListeners   = new ArrayList();
        bDisposing      = false;
        
        if (DEBUG) {
            Log.DEBUG();
            Log.debug("Inizializazion COF plugin...");
        }
        
        String cofCommand;
        try {
            cofCommand = WindowsRegistry.readRegistry(REGKEY, CLIKEY);
            if (null != cofCommand) {
                if (DEBUG) {
                    Log.debug("Leture regjistri cofCommand: '"+cofCommand+"'");
                }
            } else {
                Log.error("No register value "+REGKEY+"\\"+ CLIKEY);
                return;
            }
        } catch (java.lang.Exception ex) {
            Log.error("Erôr in leture regjistri", ex);
            return;
        } 

        if (cofCommand.equals("")) {
            Log.error("No value for "+CLIKEY+" key in cof file or registry");
            return;
        }
                
        
        try {           
            process = Runtime.getRuntime().exec(new String[] {cofCommand});
            outputStream = new BufferedReader(new InputStreamReader(process.getInputStream(),"UTF-8"));
            inputStream = new PrintStream(new BufferedOutputStream(process.getOutputStream()),true,"UTF-8");
            errorStream = new BufferedReader(new InputStreamReader(process.getErrorStream(),"UTF-8"));
            isInit=true;
            if (DEBUG) {
               Log.debug("COF inviât coretementri");
            }
        } catch (Exception ex) {
            Log.error("Error executing "+cofCommand, ex);
        }
    }

    
    private boolean IsEqual( Locale aLoc1, Locale aLoc2 )
    {
        return aLoc1.Language.equals( aLoc2.Language ) &&
               aLoc1.Country.equals( aLoc2.Country )  &&
               aLoc1.Variant.equals( aLoc2.Variant );  
    }

    private boolean IsUpper( String aWord, Locale aLocale )
    {
        java.util.Locale aLang = new java.util.Locale( 
                aLocale.Language, aLocale.Country, aLocale.Variant );
        return aWord.equals( aWord.toUpperCase( aLang ) );
    }
    
    private boolean GetValueToUse( 
            String          aPropName,
            boolean         bDefaultVal,
            PropertyValue[] aProps )
    {
        boolean bRes = bDefaultVal;

        try
        {
            
            for (int i = 0;  i < aProps.length;  ++i)
            {
                if (aPropName.equals( aProps[i].Name ))
                {
                    Object aObj = aProps[i].Value;
                    if (AnyConverter.isBoolean( aObj ))
                    {
                        bRes = AnyConverter.toBoolean( aObj );
                        return bRes;
                    }
                }
            }

            
            XPropertySet xPropSet = aPropChgHelper.GetPropSet();
            if (xPropSet != null)   
            {
                Object aObj = xPropSet.getPropertyValue( aPropName );
                if (AnyConverter.isBoolean( aObj ))
                    bRes = AnyConverter.toBoolean( aObj );
            }
        }
        catch (Exception e) {
            bRes = bDefaultVal;
        }
        
        return bRes;
    }
    
    @Override
    protected void finalize() throws Throwable {
        try {
            if (isInit) {
               inputStream.flush();
               inputStream.println("q"); 
               inputStream.flush();
               if (DEBUG) {
                    Log.debug("COF sierât");
                }
           }   
        } finally {
            super.finalize();
        }
    }
    
    public boolean initOk() {
        return isInit;
    }

    
    public Locale[] getLocales()
        throws com.sun.star.uno.RuntimeException
    {
        Locale aLocales[] = 
        {
            new Locale( "fur","IT","")
        };

        return aLocales;
    }
    
    public boolean hasLocale( Locale aLocale ) 
        throws com.sun.star.uno.RuntimeException
    {
        return IsEqual( aLocale, new Locale( "fur", "IT", "" ));
    }

    
    public boolean isValid(
            String aWord, Locale aLocale,
            PropertyValue[] aProperties ) 
        throws com.sun.star.uno.RuntimeException,
               IllegalArgumentException  
	{
        if (DEBUG) {
            Log.debug("check peraule: '"+aWord+"'...");
        }
        if (aWord.length() == 0 || !hasLocale( aLocale ) || !isInit ) {
            return true;
        }
        
        if (!GetValueToUse( "IsSpellUpperCase", false, aProperties ) && IsUpper( aWord, aLocale )) {
            return true;
        }
        
	try {
            inputStream.flush();
            inputStream.println("c "+aWord);
            inputStream.flush();
            String line = outputStream.readLine();
            line =line.trim();
            boolean result = line.equals("ok");
            if (DEBUG) {
                Log.debug(result ? "...peraule cjatade" : "...peraule no cjatade");
            }
            return result; 
	} catch (java.lang.Exception e) {	
            Log.error("Error input/output stream", e);
            return true;
        }
    }
    
    public XSpellAlternatives spell(
            String aWord, Locale aLocale,
            PropertyValue[] aProperties ) 
        throws com.sun.star.uno.RuntimeException,
               IllegalArgumentException
    {
        if (DEBUG) {
            Log.debug("suggest peraule: '"+aWord+"'...");
        }        
        
        if (aWord.length() == 0 || !hasLocale( aLocale ) || !isInit ) {
            return null;
        }
        
        if (!GetValueToUse( "IsSpellUpperCase", false, aProperties ) && IsUpper( aWord, aLocale )) {
            return null;
        }
        
        XSpellAlternatives xRes = null;

        try {
            inputStream.flush();
            inputStream.println("s "+aWord);
            inputStream.flush();            
            String line = outputStream.readLine();
            line = line.trim();
            if (line.length()==0) {
                Log.error("Error empty suggestion string");
            } else {
                String [] tocs=line.split("\t",2);
                if (tocs[0].equals("no")) {
                    String [] sugg;
                    if ((tocs.length == 1) || tocs[1].equals("")) {
                        sugg = new String[0];
                        if (DEBUG) {
                            Log.debug("...peraule falade cence sugjeriments");
                        }
                    } else {
                        sugg=tocs[1].split(",");
                        if (DEBUG) {
                            Log.debug("...peraule falade cun sugjeriments: "+tocs[1]);
                        }
                    }
                    xRes=new  XSpellAlternatives_impl(aWord,aLocale,SpellFailure.SPELLING_ERROR, sugg);
                } else if (DEBUG) {
                    Log.debug("...peraule corete");
                }
            }
        } catch (IOException ex) {
            Log.error("Error reading suggestion string", ex);    
            return null;
        }

        return xRes;
    }

    
    public boolean addLinguServiceEventListener (
            XLinguServiceEventListener xLstnr )
        throws com.sun.star.uno.RuntimeException
    {
        boolean bRes = false;   
        if (!bDisposing && xLstnr != null)
            bRes = aPropChgHelper.addLinguServiceEventListener( xLstnr );
        return bRes;
    }
    
    public boolean removeLinguServiceEventListener(
            XLinguServiceEventListener xLstnr ) 
        throws com.sun.star.uno.RuntimeException
    {
        boolean bRes = false;   
        if (!bDisposing && xLstnr != null)
            bRes = aPropChgHelper.removeLinguServiceEventListener( xLstnr );
        return bRes;
    }            

    
    public String getServiceDisplayName( Locale aLocale ) 
        throws com.sun.star.uno.RuntimeException
    {
        return "Coretôr Ortografic Furlan";                                                    
    }


    public void initialize( Object[] aArguments ) 
        throws com.sun.star.uno.Exception,
               com.sun.star.uno.RuntimeException
    {
        int nLen = aArguments.length;
        if (2 == nLen)
        {
            XPropertySet xPropSet = (XPropertySet)UnoRuntime.queryInterface(
                                         XPropertySet.class, aArguments[0]);
            
            aPropChgHelper.AddAsListenerTo( xPropSet );
        }
    }
    
    public boolean supportsService( String aServiceName )
        throws com.sun.star.uno.RuntimeException
    {
        String[] aServices = getSupportedServiceNames_Static();
        int i, nLength = aServices.length;
        boolean bResult = false;

        for( i = 0; !bResult && i < nLength; ++i )
            bResult = aServiceName.equals( aServices[ i ] );

        return bResult;
    }

    public String getImplementationName()
        throws com.sun.star.uno.RuntimeException
    {
        return _aSvcImplName;
    }
        
    public String[] getSupportedServiceNames()
        throws com.sun.star.uno.RuntimeException
    {
        return getSupportedServiceNames_Static();
    }
    
    

    public static String _aSvcImplName = COFSpeller.class.getName();
    
    public static String[] getSupportedServiceNames_Static()
    {
        String[] aResult = { "com.sun.star.linguistic2.SpellChecker" };
        return aResult;
    }

    
    public static XSingleServiceFactory __getServiceFactory(
        String aImplName,
        XMultiServiceFactory xMultiFactory,
        com.sun.star.registry.XRegistryKey xRegKey )
    {
        XSingleServiceFactory xSingleServiceFactory = null;
        if( aImplName.equals( _aSvcImplName ) )
        {
            xSingleServiceFactory = new OneInstanceFactory(
                    COFSpeller.class, _aSvcImplName,
                    getSupportedServiceNames_Static(),
                    xMultiFactory );
        }
        return xSingleServiceFactory;
    }

    
    public static boolean __writeRegistryServiceInfo( 
            com.sun.star.registry.XRegistryKey xRegKey )
    {
        boolean bResult = true;
        String[] aServices = getSupportedServiceNames_Static();
        int i, nLength = aServices.length;
        for( i = 0; i < nLength; ++i )
        {
            bResult = bResult && com.sun.star.comp.loader.FactoryHelper.writeRegistryServiceInfo(
                _aSvcImplName, aServices[i], xRegKey );
        }
        return bResult;
    }
    
    public static void main(String[] argv) {
        COFSpeller cof=new COFSpeller();
        System.out.println("Pe version viôt in description.xml tal pkg\n");
        if (!cof.isInit) {
            System.err.println("Erôr te inizializazion dal COF");
            System.exit(1);
        }
        PropertyValue[] prop=null;
        Locale locale=new Locale("fur", "IT", "" );
        if (argv.length==0) {
            System.out.println("Nissune peraule furnide di controlâ");
            System.exit(0);
        }
        for (String w: argv) {
            try {
                if (!cof.isValid(w,locale,prop)) {
                      System.out.println(w+" falade");
                      System.out.print("\tsugjeriments: ");
                      for (String sug: cof.spell(w,locale,prop).getAlternatives()) {
                          System.out.print(sug+" ");
                      }
                      System.out.println();
                } else {
                    System.out.println(w+" juste");
                }
            } catch (IllegalArgumentException ex) {
                ex.printStackTrace(System.err);
            } catch (RuntimeException ex) {
                ex.printStackTrace(System.err);
            }
        }
    }
}
