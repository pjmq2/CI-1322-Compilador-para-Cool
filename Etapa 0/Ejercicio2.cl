Class List inherits IO { 
	isNil() : Bool { { abort(); true; } };
	cons(hd : Int) : Cons {
	  (let new_cell : Cons <- new Cons in
		new_cell.init(hd,self,true)
	  )
	};

	car() : Int { { abort(); new Int; } };

	cdr() : List { { abort(); new List; } };

	insert(i : Int) : List { cdr() };

	rcons(i : Int) : List { cdr() };
	
	print_list() : Object { abort() };

	cambio_bool(i : Int) : Object { abort() };
};

Class Cons inherits List {
	xcar : Int;
	xcdr : List;
	esPrimo : Bool;

	isNil() : Bool { false };

	init(hd : Int, tl : List, pr : Bool) : Cons {
	  {
	    xcar <- hd;
	    xcdr <- tl;
	    esPrimo <- pr;
	    self;
	  }
	};
	  
	car() : Int { xcar };

	cdr() : List { xcdr };

	insert(i : Int) : List {
		if i < xcar then
			(new Cons).init(i,self,true)
		else
			(new Cons).init(xcar,xcdr.insert(i),true)
		fi
	};


	rcons(i : Int) : List { (new Cons).init(xcar, xcdr.rcons(i),true) };

	print_list() : Object {
		if esPrimo
		then {
			out_int(xcar).out_string("\n");
			xcdr.print_list();
		}
		else {
			xcdr.print_list();
		}
		fi
	};

	cambio_bool(i : Int) : Object {
		if i < xcar
		then {
			xcdr.cambio_bool(i);
		}
		else esPrimo <- false
		fi
	};
};

Class Nil inherits List {
	isNil() : Bool { true };

        rev() : List { self };

	rcons(i : Int) : List { (new Cons).init(i,self,true) };

	print_list() : Object { true };

};


Class Main inherits IO {

	l : List;
	num : Int;

	iota(i : Int) : List {
	    {
		l <- new Nil;
		(let j : Int <- 1 in
		   while j < i+1
		   loop 
		     {
		       l <- (new Cons).init(j,l,true);
		       j <- j + 1;
		     } 
		   pool
		);
		l;
	    }
	};

	criba() : Object{
		{
		
			(let i : Int <- 2 in
			while i < num
	   		loop 
	    		{
				(let j : Int <- 2 in
				while j < i*i
				loop{
					l.cambio_bool(i*j);
					j <- j + 1;
				}
				pool
				);
				i <- i + 1;
			} 
			pool
			);	
			
		}
	};

	main() : Object {
	   {
	     out_string("\n");
	     num <- in_int();
	     out_string("\n").out_string("Los numeros primos de 0 a ").out_int(num).out_string(" son: \n");
	     iota(num);
	     criba();
	     l.print_list();
	   }
	};
};			    
