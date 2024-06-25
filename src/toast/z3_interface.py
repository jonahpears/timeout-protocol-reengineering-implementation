from z3 import *

# x = Int('x')
# print(f"simplify: {simplify(And(x==4,x>3))}")
# # print(f"solve: {solve(x==4,x>3)}")

# x, n = Ints('x n')
# t, t_ = Reals('t t_')
# s = Solver()
# s.add(x==4, t==0.30259726, n==3)
# s.add(Exists(t_,And(0<=t_,t_<t, (x+t_) > n)))
# result = s.check()

# print(f"solver: {s}.")
# print(f"result: {result}.")

# x, n = Ints('x n')
# t, t_ = Reals('t t_')
# s = Solver()
# s.add(x==2,n==8,t==5.0)
# s.add(Exists(t_,And(t_<t, (x+t_)>n)))
# print(f"model: {s.model()}.")
# print(f"solver: {s}.\n")
# print(f"proof: {s,proof()}.")
# print(f"solve: {s,solve()}.")
# print(f"check: {s.check()}.")

# # y = Int('y')
# # print (simplify(x + y + 2*x + 3))
# # print (simplify(x < y + x + 2))
# # print (simplify(And(x + 1 >= 3, x**2 + x**2 + y**2 + 2 >= 5)))

# # print(solve(x == 4,x<3))

# s = Solver()
# print (f"s: {s}.")

# s.add(x==2,x>3)
# print (f"\nSolving constraints in the solver s:\n\t{s}.")
# print (s.check())

# s.add(x > 10, y == x + 2)
# print (f"\nSolving constraints in the solver s:\n\t{s}.")
# print (s.check())

# print ("\nCreate a new scope...")
# s.push()
# s.add(y < 11)
# print (f"Solving updated set of constraints in s:\n\t{s}.")
# print (s.check())

# print ("\nRestoring state...")
# s.pop()
# print (f"Solving restored set of constraints in s:\n\t{s}.")
# print (s.check())


CONST_DECIMAL_PRECISION = 8


# Tie, Shirt = Bools('Tie Shirt')
# s = Solver()
# s.add(Or(Tie, Shirt), 
#       Or(Not(Tie), Shirt), 
#       Or(Not(Tie), Not(Shirt)))
# print(s.check())
# print(s.model())


# S = DeclareSort('')

# Type = Datatype('Tree')
# Process = Datatype('Tree')

## is t-reading
def is_t_reading(Delta:dict,t:float):
  
  Result = solve([])

## get value of clock from Delta, use "global" if not present
def get_clock_value(Delta:dict,Clock:str):
  assert "global" in Delta.keys()
  Delta.setdefault(Clock,Delta["global"])
  return Delta, Delta.get(Clock)
  
## reset value of clock in Delta, except "global"
def reset_clocks(Delta:dict,Clocks:list):
  assert "global" in Delta.keys()
  assert "global" not in Clocks
  for Clock in Clocks:
    Delta = reset_clock(Delta,Clock)
  return Delta
    
def reset_clock(Delta:dict,Clock:str):
  Delta[Clock] = 0
  return Delta

## provides Delta with "global" clock
def new_delta(Init:int=0):
  return {"global":Init}

## passes time over clocks
def time_step(Delta:dict,Step:float):
  for Clock in Delta.keys():
    Delta[Clock] =  round(Delta.get(Clock)+Step, CONST_DECIMAL_PRECISION)
  return Delta


# Delta = new_delta()
# print(f"initial Delta:\t{Delta}.")

# Delta = time_step(Delta,4.2)
# print(f"time step:\t{Delta}.")
  
# Delta,Value_X = get_clock_value(Delta,"x")
# print(f"checked x:\t{Delta}.")

# Delta = time_step(Delta,1.2)
# print(f"time step:\t{Delta}.")
  
# Delta = reset_clock(Delta,"x")
# print(f"reset x:\t{Delta}.")

# Delta = time_step(Delta,1.2)
# print(f"time step:\t{Delta}.")

# Delta = reset_clock(Delta,"y")
# print(f"reset y:\t{Delta}.")

# Delta = time_step(Delta,1.2)
# print(f"time step:\t{Delta}.")



## for interfacing with erlang
def test(Constraints):
  print(f"python received: {Constraints}.")
  
  return "from python"


# def not_t_reading(Tuple:tuple):
#   ## unpack
#   (Clocks,T) = Tuple
#   print(f"\nclocks:\t{Clocks},\nt:\t {T}.")
  
#   # C1 = Clocks.pop(),
  
#   # print(f"\nC1:\t{C1}.")
  
## for receiving code to execute that will ask z3
def ask_z3(codeBinary:str):
  # print(f"ask_z3, binary code: {codeBinary}.")
  codeString = codeBinary.decode("utf-8")
  # print(f"ask_z3, executing: {codeString}.")
  local = {}
  exec(codeString, globals(), local)
  result = local['result']==sat
  # print(f"ask_z3, finished: {result}.")
  return result

