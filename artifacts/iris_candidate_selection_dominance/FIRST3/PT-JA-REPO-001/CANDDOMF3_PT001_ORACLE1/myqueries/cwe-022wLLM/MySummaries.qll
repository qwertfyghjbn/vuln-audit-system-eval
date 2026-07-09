import java
import semmle.code.java.dataflow.DataFlow
private import semmle.code.java.dataflow.ExternalFlow

predicate isGPTDetectedStep(DataFlow::Node prev, DataFlow::Node next) {
    exists(Call c |
        (c.getArgument(_) = prev.asExpr() or c.getQualifier() = prev.asExpr())
        and c.getCallee().getDeclaringType().hasQualifiedName("java.nio.file", "Paths")
        and c.getCallee().getName() = "get"
        and c = next.asExpr()
    )
}
