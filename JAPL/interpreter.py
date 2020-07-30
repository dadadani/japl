import operator
from typing import List
from .types.callable import Callable
from .meta.environment import Environment
from .meta.tokentype import TokenType
from .types.native import Clock, Type, JAPLFunction, Truthy, Stringify
from .meta.exceptions import JAPLError, BreakException, ReturnException
from .meta.expression import Expression, Variable, Literal, Logical, Binary, Unary, Grouping, Assignment, Call
from .meta.statement import Statement, Print, StatementExpr, If, While, Del, Break, Return, Var, Block, Function


class Interpreter(Expression.Visitor, Statement.Visitor):
    """
       An interpreter for the JAPL
       programming language
    """

    OPS = {TokenType.MINUS: operator.sub, TokenType.PLUS: operator.add, TokenType.SLASH: operator.truediv,
           TokenType.STAR: operator.mul, TokenType.DEQ: operator.eq, TokenType.GT: operator.gt,
           TokenType.GE: operator.ge, TokenType.LT: operator.lt, TokenType.LE: operator.le, TokenType.EQ: operator.eq,
           TokenType.NE: operator.ne, TokenType.MOD: operator.mod, TokenType.POW: operator.pow}

    def __init__(self):
        """Object constructor"""

        self.environment = Environment()
        self.locals = {}
        self.globals = self.environment
        self.globals.define("clock", Clock())
        self.globals.define("type", Type())
        self.globals.define("truthy", Truthy())
        self.globals.define("stringify", Stringify())
        self.looping = False
        self.in_function = False

    def number_operand(self, op, operand):
        """
        An helper method to check if the operand
        to a unary operator is a number
        """

        if isinstance(operand, (int, float)):
            return
        raise JAPLError(op,
                        f"Unsupported unary operator '{op.lexeme}' for object of type '{type(operand).__name__}'")

    def compatible_operands(self, op, left, right):
        """
        Helper method to check types when doing binary
        operations
        """

        if op.kind == TokenType.SLASH and right == 0:
            raise JAPLError(op, "Cannot divide by 0")
        elif isinstance(left, (bool, type(None))) or isinstance(right, (bool, type(None))):
            if op.kind not in (TokenType.DEQ, TokenType.NE):
                raise JAPLError(op, f"Unsupported binary operator '{op.lexeme}' for objects of type '{type(left).__name__}' and '{type(right).__name__}'")
            return
        elif isinstance(left, (int, float)) and isinstance(right, (int, float)):
            return
        elif op.kind in (TokenType.PLUS, TokenType.STAR, TokenType.DEQ, TokenType.NE):
            if isinstance(left, str) and isinstance(right, str):
                return
            elif isinstance(left, str) and isinstance(right, int):
                return
            elif isinstance(left, int) and isinstance(right, str):
                return
        raise JAPLError(operator, f"Unsupported binary operator '{op.lexeme}' for objects of type '{type(left).__name__}' and '{type(right).__name__}'")

    def visit_literal(self, expr: Literal):
        """
           Visits a Literal node in the Abstract Syntax Tree,
           returning its value to the visitor
        """

        return expr.value

    def visit_logical(self, expr: Logical):
        """Visits a logical node"""

        left = self.eval(expr.left)
        if expr.operator.kind == TokenType.OR:
            if bool(left):
                return left
            elif not bool(left):
                return self.eval(expr.right)
        return self.eval(expr.right)

    def eval(self, expr: Expression):
        """
        Evaluates an expression by calling its accept()
        method and passing self to it. This mechanism is known
        as the 'Visitor Pattern': the expression object will
        later call the interpreter's appropriate method to
        evaluate itself
        """

        return expr.accept(self)

    def visit_grouping(self, grouping: Grouping):
        """
        Visits a Grouping node in the Abstract Syntax Tree,
        recursively evaluating its subexpressions
        """

        return self.eval(grouping.expr)

    def visit_unary(self, expr: Unary):
        """
        Visits a Unary node in the Abstract Syntax Teee,
        returning the negation of the given object, if
        the operation is supported
        """

        right = self.eval(expr.right)
        self.number_operand(expr.operator, right)
        if expr.operator.kind == TokenType.NEG:
            return not right
        return -right

    def visit_binary(self, expr: Binary):
        """
        Visits a Binary node in the Abstract Syntax Tree,
        recursively evaulating both operands first and then
        performing the operation specified by the operator
        """

        left = self.eval(expr.left)
        right = self.eval(expr.right)
        self.compatible_operands(expr.operator, left, right)
        return self.OPS[expr.operator.kind](left, right)

    def visit_print(self, stmt: Print):
        """
        Visits the print statement node in the AST and
        evaluates its expression before printing it to
        stdout
        """

        val = self.eval(stmt.expression)
        print(val)

    def visit_statement_expr(self, stmt: StatementExpr):
        """
        Visits an expression statement and evaluates it
        """

        self.eval(stmt.expression)

    def visit_if(self, statement: If):
        """
        Visits an If node and evaluates it
        """

        if self.eval(statement.condition):
            self.exec(statement.then_branch)
        elif statement.else_branch:
            self.exec(statement.else_branch)

    def visit_while(self, statement: While):
        """
        Visits a while node and executes it
        """

        self.looping = True
        while self.eval(statement.condition):
            try:
                self.exec(statement.body)
            except BreakException:
                break
        self.looping = False

    def visit_var_stmt(self, stmt: Var):
        """
        Visits a var statement
        """

        val = None
        if stmt.init:
            val = self.eval(stmt.init)
        self.environment.define(stmt.name.lexeme, val)

    def lookup(self, name, expr: Expression):
        """
        Performs name lookups in the closest scope
        """

        distance = self.locals.get(expr)
        if distance is not None:
            return self.environment.get_at(distance, name.lexeme)
        else:
            return self.globals.get(name)

    def visit_var_expr(self, expr: Variable):
        """
        Visits a var expression
        """

        return self.lookup(expr.name, expr)

    def visit_del(self, stmt: Del):
        """
        Visits a del expression
        """

        return self.environment.delete(stmt.name)

    def visit_assign(self, stmt: Assignment):
        """
        Visits an assignment expression
        """

        right = self.eval(stmt.value)
        distance = self.locals.get(stmt)
        if distance is not None:
            self.environment.assign_at(distance, stmt.name, right)
        else:
            self.globals.assign(stmt.name, right)
        return right

    def visit_block(self, stmt: Block):
        """
        Visits a new scope block
        """

        return self.execute_block(stmt.statements, Environment(self.environment))

    def visit_break(self, stmt: Break):
        """
        Visits a break statement
        """

        if self.looping:
            raise BreakException()
        raise JAPLError(stmt.token, "'break' outside loop")

    def visit_call_expr(self, expr: Call):
        """
        Visits a call expression
        """

        callee = self.eval(expr.callee)
        if not isinstance(callee, Callable):
            raise JAPLError(expr.paren, f"'{type(callee).__name__}' is not callable")
        arguments = []
        for argument in expr.arguments:
            arguments.append(self.eval(argument))
        function = callee
        if function.arity != len(arguments):
            raise JAPLError(expr.paren, f"Expecting {function.arity} arguments, got {len(arguments)}")
        return function.call(self, arguments)

    def execute_block(self, statements: List[Statement], scope: Environment):
        """
        Executes a block of statements
        """

        prev = self.environment
        try:
            self.environment = scope
            for statement in statements:
                self.exec(statement)
        finally:
            self.environment = prev

    def visit_return(self, statement: Return):
        """
        Visits a return statement
        """

        if self.in_function:
            value = None
            if statement.value:
                value = self.eval(statement.value)
            raise ReturnException(value)
        else:
            raise JAPLError(statement.keyword, "'return' outside function")

    def visit_function(self, statement: Function):
        """
        Visits a function
        """

        function = JAPLFunction(statement, self.environment)
        self.environment.define(statement.name.lexeme, function)

    def exec(self, statement: Statement):
        """
        Executes a statement
        """

        statement.accept(self)

    def interpret(self, statements: List[Statement]):
        """
        Executes a JAPL program
        """

        for statement in statements:
            self.exec(statement)

    def resolve(self, expr: Expression, depth: int):
        """
        Stores the result of the name resolution: this
        info will be used later to know exactly in which
        environment to look up a given variable
        """

        self.locals[expr] = depth  # How many environments to skip!
