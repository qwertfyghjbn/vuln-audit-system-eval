import java
import semmle.code.java.dataflow.DataFlow
private import semmle.code.java.dataflow.ExternalFlow

predicate isGPTDetectedSink(DataFlow::Node snk) {
    exists(Call c |
        c.getCallee().getName() = "readAllBytes" and
        c.getCallee().getDeclaringType().getSourceDeclaration().hasQualifiedName("java.nio.file", "Files") and
        ( c.getArgument(0) = snk.asExpr().(Argument) )
    )
}


