import java
import semmle.code.java.dataflow.DataFlow
private import semmle.code.java.dataflow.ExternalFlow

predicate isGPTDetectedSink(DataFlow::Node snk) {
    exists(Call c |
        c.getCallee().getName() = "getForObject" and
        c.getCallee().getDeclaringType().getSourceDeclaration().hasQualifiedName("org.springframework.web.client", "RestTemplate") and
        ( c.getArgument(0) = snk.asExpr().(Argument) )
    )
}


