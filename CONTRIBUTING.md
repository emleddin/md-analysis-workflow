# Contribuing to the MD-analysis-workflow

:wave: :tada: Welcome! Glad you're here! :tada:

## Styleguide
- Please keep lines as close to 80 characters as you can. 
  That's not always feasible with Python or Markdown, but it makes things 
  so much easier to edit!
- When writing in markdown files, please start new sentences on their own line.
- Create a `help` comment in new rules. 
  This should go directly below the rule definition (such as `rule rulename:`).
  
  The help syntax is:
  ```python
  #! rulename         : An explanation of rule and what it does goes here. Line
  #!                    Line continuations start at same position for 
  #!                    improved readability.
  #!                    Aren't you glad you're helping document the code? I am!
  #!
  ``` 
  The `#!` needs to be at the start of the line, and the colon (`:`) should be 
  at position 21.
  You should add an extra line starting with `#!` after the explanation to 
  separate out the rules when printed.
  Capitalization doesn't matter. :sunglasses:
- Function definitions should have a 
  [numpy-style](https://numpydoc.readthedocs.io/en/latest/format.html) 
  docstring.
- Add a link to the citation page for any additional packages or programs in 
  the `README.md` file.
- Try to keep things tidy. 
  Group related bits of code in directories or files.
