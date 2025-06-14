test:
	busted lua/tests

# Assumes $HOME/git/panvimdoc is a clone of https://github.com/kdheepak/panvimdoc
vimdoc:
	../panvimdoc/panvimdoc.sh --project-name executor --input-file README.md --toc true --treesitter true --doc-mapping false --doc-mapping-project-name false --ignore-rawblocks true --shift-heading-level-by 0 --increment-heading-level-by 0

