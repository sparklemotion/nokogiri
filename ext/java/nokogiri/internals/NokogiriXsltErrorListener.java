package nokogiri.internals;

import javax.xml.transform.ErrorListener;
import javax.xml.transform.TransformerException;

/**
 * Error Listener for XSLT transformer
 *
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class NokogiriXsltErrorListener implements ErrorListener
{
  public enum ErrorType {
    SUCCESS,
    WARNING,
    ERROR,
    FATAL
  }

  private ErrorType type = ErrorType.SUCCESS;
  private String errorMessage = null;
  private Exception exception = null;

  public void
  warning(TransformerException ex)
  {
    type = ErrorType.WARNING;
    setError(ex);
  }

  public void
  error(TransformerException ex)
  {
    type = ErrorType.ERROR;
    setError(ex);
  }

  public void
  fatalError(TransformerException ex)
  {
    type = ErrorType.FATAL;
    setError(ex);
  }

  private void
  setError(TransformerException ex)
  {
    errorMessage = ex.getMessage();
    exception = ex;
  }

  public String
  getErrorMessage()
  {
    return errorMessage;
  }

  public ErrorType
  getErrorType()
  {
    return type;
  }

  public Exception
  getException()
  {
    return exception;
  }

}
