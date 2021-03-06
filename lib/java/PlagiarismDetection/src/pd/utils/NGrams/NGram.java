/*
This file is part of SSID.

SSID is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

SSID is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with SSID.  If not, see <http://www.gnu.org/licenses/>.
 */

package pd.utils.NGrams;

import pd.utils.Tokens.*;
import java.util.*;

public class NGram {

	private int hashCode = 0, codeStartLoc = -1, codeEndLoc = -1,
			codeStartLine = -1;
	private TokenList tokens = new TokenList();
	// private ArrayList<Integer> endOfStmtTokenIndices = new
	// ArrayList<Integer>(), startOfStmtTokenIndices = new ArrayList<Integer>();
	private static int nGramSize = 0;
	private boolean firstTokenStartOfStmt = false;

	public static void setNGramSize(int size) {
		nGramSize = size;
	}

	public static int getNGramSize() {
		return nGramSize;
	}

	public int getCurrentTokenCount() {
		return tokens.size();
	}

	public boolean isFirstTokenStartOfStmt() {
		return firstTokenStartOfStmt;
	}

	public int codeStartIndex() {
		return codeStartLoc;
	}

	public int codeEndIndex() {
		return codeEndLoc;
	}

	public int getCodeStartLine() {
		return codeStartLine;
	}

	public static NGram clone(int startIndex, NGram nGram) {
		NGram reply = new NGram();
		TokenList tokens = nGram.tokens;
		reply.append(startIndex, tokens);
		// reply.setHashCode(nGram.hashCode);
		return reply;
	}

	public void setHashCode(int hashCode) {
		this.hashCode = hashCode;
	}

	private void append(int startIndex, TokenList tokens) {
		for (Token t : tokens) {
			append(startIndex++, t);
		}
	}

	public void append(int index, Token t) {
		if (codeStartLoc == -1) {
			codeStartLoc = t.getCodeStartIndex();
			codeStartLine = t.getCodeLine();
			firstTokenStartOfStmt = t.isStartOfStatement();
		}

		codeEndLoc = t.getCodeEndIndex();

		// if (t.isEndOfStatement()) {
		// endOfStmtTokenIndices.add(index);
		// }
		// if (t.isStartOfStatement()) {
		// startOfStmtTokenIndices.add(index);
		// }

		// hashCode = hashCode << Token.getBitRequired() | t.hashCode();
		hashCode = hashCode * Token.getRegCount() + t.hashCode();
		tokens.add(t);
	}

	@Override
	public int hashCode() {
		return hashCode;
	}

	@Override
	public boolean equals(Object obj) {
		if (obj == null || getClass() != obj.getClass()) {
			return false;
		}

		if (obj == this) {
			return true;
		}

		Iterator<Token> i = tokens.iterator();
		Iterator<Token> other = ((NGram) obj).tokens.iterator();

		while (i.hasNext() && other.hasNext()) {
			if (!(i.next().equals(other.next()))) {
				return false;
			}
		}

		return !(i.hasNext() || other.hasNext());
	}
}
