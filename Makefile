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

check-docs:
	@make vimdoc
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "Git status is not clean after generating docs"; \
		git status; \
		exit 1; \
	else \
		echo "Git status is clean - docs are up to date"; \
	fi

setup-hooks:
	@echo "Setting up git hooks..."
	@cp scripts/hooks/* .git/hooks/
	@chmod +x .git/hooks/*
	@echo "Git hooks installed successfully"

