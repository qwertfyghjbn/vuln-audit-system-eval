import java
import semmle.code.java.dataflow.DataFlow
private import semmle.code.java.dataflow.ExternalFlow

predicate isGPTDetectedSource(DataFlow::Node src) {
    exists(Parameter p |
        src.asParameter() = p and
        p.getCallable().getName() = "readFile" and
        p.getCallable().getDeclaringType().getSourceDeclaration().hasQualifiedName("com.example.demo.util", "FileUtil") and
        ( p.getName() = "filename" )
    )
}


