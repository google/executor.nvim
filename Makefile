test:
	busted lua/tests

# Clone panvimdoc repo locally if it doesn't exist, then update it
clone-panvimdoc:
	@if [ ! -d .panvimdoc-clone ]; then \
		echo "Cloning panvimdoc..."; \
		git clone https://github.com/kdheepak/panvimdoc .panvimdoc-clone; \
	else \
		echo "Updating panvimdoc..."; \
		cd .panvimdoc-clone && git pull; \
	fi

vimdoc: clone-panvimdoc
	./.panvimdoc-clone/panvimdoc.sh \
		--project-name executor \
		--input-file README.md \
		--toc true \
		--treesitter true \
		--doc-mapping false \
		--doc-mapping-project-name false \
		--ignore-rawblocks true \
		--shift-heading-level-by 0 \
		--dedup-subheadings true \
		--increment-heading-level-by 0

