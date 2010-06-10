
console: typesafty_console.rb
	ruby typesafty_console.rb

result : rmof_test.rb
	ruby rmof_basic_test.rb
	ruby rmof_test.rb

tags : *.rb 
	ctags -R *.rb

clean :
	rm tags
	rm tmp/*
	rmdir tmp
